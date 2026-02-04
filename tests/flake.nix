{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    landrun-nix.url = "path:../";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      imports = [ inputs.landrun-nix.flakeModule ];

      perSystem = { config, pkgs, ... }:
        let
          testDeps = [ pkgs.bats ] ++ (builtins.attrValues config.packages);
        in
        {
          landrunApps = {
            test-true = {
              program = "${pkgs.coreutils}/bin/true";
            };
            test-ls = {
              program = "${pkgs.coreutils}/bin/ls";
              features.tty = false;
            };
            test-curl-deny = {
              program = "${pkgs.curl}/bin/curl";
              features.network = false;
            };
            test-curl-allow = {
              program = "${pkgs.curl}/bin/curl";
              features.network = true;
            };
            test-env-var = {
              program = "${pkgs.bash}/bin/bash";
              cli.env = [ "MY_TEST_VAR" ];
            };
            test-read-access = {
              program = "${pkgs.bash}/bin/bash";
              cli.ro = [ "./test_secret" ];
            };
            test-write-access = {
              program = "${pkgs.bash}/bin/bash";
              cli.rw = [ "./test_secret" ];
            };
            test-no-access = {
              program = "${pkgs.bash}/bin/bash";
            };
            test-multi-paths = {
              program = "${pkgs.bash}/bin/bash";
              cli = {
                ro = [ "./ro1" "./ro2" ];
                rw = [ "./rw1" "./rw2" ];
                rox = [ "./rox1" "./rox2" ];
                rwx = [ "./rwx1" "./rwx2" ];
              };
            };
            test-nested-paths = {
              program = "${pkgs.bash}/bin/bash";
              cli = {
                ro = [ "./parent" ];
                rw = [ "./parent/child" ];
              };
            };
            test-multi-env = {
              program = "${pkgs.bash}/bin/bash";
              cli.env = [ "VAR1" "VAR2" ];
            };
            test-special-env = {
              program = "${pkgs.bash}/bin/bash";
              cli.env = [ "SPECIAL_VAR" ];
            };
            test-unrestricted-fs = {
              program = "${pkgs.bash}/bin/bash";
              cli.unrestrictedFilesystem = true;
            };
            test-add-exec-disabled = {
              program = "${pkgs.bash}/bin/bash";
              cli.addExec = false;
            };
            test-extra-args = {
              program = "${pkgs.bash}/bin/bash";
              # We pass -v (verbose) to landrun via extraArgs
              cli.extraArgs = [ "-v" ];
            };
          };

          devShells.default = pkgs.mkShell {
            packages = testDeps;
          };

          checks.tests = pkgs.runCommand "tests"
            {
              __impure = true;
              nativeBuildInputs = [ pkgs.bats ] ++ testDeps;
            } ''
            export HOME=home
            mkdir -p $HOME
            mkdir -p $HOME/.cache/nix

            export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

            bats ${./test.bats} > $out
          '';
        };
    };
}
