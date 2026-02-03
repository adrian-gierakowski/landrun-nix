{ lib
, config
, pkgs
, name
, ...
}:
let
  inherit (lib) concatMapStringsSep optionalString;

  linuxWrapper =
    let
      # Helper to generate conditional path argument
      conditionalPathArg =
        flag: paths:
        lib.concatMapStringsSep "\n"
          (p: ''
            if [ -e "${p}" ]; then
              args+=("${flag}" "${p}")
            fi
          '')
          paths;

      # Static args (non-path related)
      staticArgs = lib.concatStringsSep " \\\n      " (
        [ ]
        ++ (map (p: "--rwx \"${p}\"") config.cli.rwx)
        ++ (map (p: "--rw \"${p}\"") config.cli.rw)
        ++ (map (e: "--env ${e}") config.cli.env)
        ++ (lib.optional config.cli.unrestrictedNetwork "--unrestricted-network")
        ++ (lib.optional config.cli.unrestrictedFilesystem "--unrestricted-filesystem")
        ++ (lib.optional config.cli.addExec "--add-exec")
        ++ config.cli.extraArgs
      );
    in
    (pkgs.writeShellApplication {
      name = name;
      runtimeInputs = [ pkgs.landrun ];
      text = ''
        args=()

        # Add conditional --rox paths
        ${conditionalPathArg "--rox" config.cli.rox}

        # Add conditional --ro paths
        ${conditionalPathArg "--ro" config.cli.ro}

        exec landrun \
          "''${args[@]}" \
          ${staticArgs} \
          ${config.program} "$@"
      '';
    });

  darwinWrapper =
    let
      staticProfile = import ./sandbox-profile.nix { inherit config lib; };

      appendRules =
        rule: paths:
        concatMapStringsSep "\n"
          (p: ''
            EXPANDED_PATH="${p}"
            # Escape double quotes for sandbox profile
            ESCAPED_PATH="''${EXPANDED_PATH//\"/\\\"}"
            echo "(${rule} (subpath \"$ESCAPED_PATH\"))" >> "$PROFILE_FILE"
          '')
          paths;
    in
    (pkgs.writeShellApplication {
      name = name;
      runtimeInputs = [ pkgs.coreutils ]; # for realpath, mktemp
      text = ''
        set -euo pipefail

        # Create temp profile
        PROFILE_FILE="$(mktemp -t landrun_sandbox.XXXXXX)"
        trap 'rm -f "$PROFILE_FILE"' EXIT

        # Write static profile
        cat > "$PROFILE_FILE" <<EOF
        ${staticProfile}
        EOF

        # Append dynamic rules based on existing paths

        # ro
        ${appendRules "allow file-read*" config.cli.ro}

        # rw
        ${appendRules "allow file-read* file-write*" config.cli.rw}

        # rox
        ${appendRules "allow file-read* process-exec" config.cli.rox}

        # rwx
        ${appendRules "allow file-read* file-write* process-exec" config.cli.rwx}

        # addExec
        ${optionalString config.cli.addExec ''
          PROG_PATH="${config.program}"
          # Resolve command if it's not absolute (though typically it is in nix)
          if [ -e "$PROG_PATH" ]; then
             ESCAPED_PROG="''${PROG_PATH//\"/\\\"}"
             echo "(allow file-read* process-exec (subpath \"$ESCAPED_PROG\"))" >> "$PROFILE_FILE"
          fi
        ''}

        # Claude Workaround
        ${optionalString config.features.claudeWorkaround ''
          function escape_for_sandbox() {
              local path="$1"
              path="''${path//\\/\\\\}"
              path="''${path//\"/\\\"}"
              echo "$path"
          }

          function generate_workaround() {
              local tgt_dir
              tgt_dir="$(pwd)"
              # Ensure path starts with /
              if [[ ! "''${tgt_dir}" =~ ^/ ]]; then
                  tgt_dir="$(realpath "$tgt_dir")"
              fi

              local components=()
              IFS='/' read -ra components <<< "''${tgt_dir}"

              local current_path=""

              echo "" >> "$PROFILE_FILE"
              echo ";; Claude Workaround for $tgt_dir" >> "$PROFILE_FILE"

              for component in "''${components[@]}"; do
                  if [[ -z "''${component}" ]]; then
                      if [[ -z "''${current_path}" ]]; then
                          current_path="/"
                      fi
                      continue
                  fi

                  if [[ "''${current_path}" == "/" ]]; then
                      current_path="/$component"
                  else
                      current_path="$current_path/$component"
                  fi

                  local escaped_path
                  escaped_path="$(escape_for_sandbox "''${current_path}")"

                  echo "(allow file-read* (literal \"''${escaped_path}\"))" >> "$PROFILE_FILE"
              done
          }

          generate_workaround
        ''}

        # Export environment variables
        ${concatMapStringsSep "\n" (e: "export ${e}") config.cli.env}

        # Execute
        exec sandbox-exec -f "$PROFILE_FILE" \
          -D HOME="$HOME" \
          -D USER="$USER" \
          "${config.program}" "$@"
      '';
    });
in
{
  config = {
    wrappedPackage = (if pkgs.stdenv.hostPlatform.isDarwin then darwinWrapper else linuxWrapper) // {
      meta = config.meta;
    };
  };
}
