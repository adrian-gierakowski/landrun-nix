{ config, lib }:
let
  cfg = config;
  inherit (lib) optionalString concatMapStringsSep;

  # Base system paths to allow reading and execution
  systemPaths = [
    "/usr"
    "/bin"
    "/sbin"
    "/opt"
    "/var"
    "/private/var"
    "/etc"
    "/private/etc"
    "/System"
    "/Library"
  ];

  allowPaths = rule: paths:
    concatMapStringsSep "\n" (p: "(${rule} (subpath \"${p}\"))") paths;
in
''
  (version 1)
  (deny default)

  ;; Allow signals to same sandbox
  (allow signal (target same-sandbox))
  (allow process-fork)
  (allow process-info*)

  ;; Standard I/O
  (allow file-read* file-write*
      (literal "/dev/null")
      (literal "/dev/zero")
      (literal "/dev/dtracehelper")
      (literal "/dev/urandom")
      (literal "/dev/random")
      (literal "/dev/ptmx")
  )

  ;; TTY support
  ${if cfg.features.tty then ''
  (allow file-read* file-write*
      (regex #"^/dev/tty.*")
      (regex #"^/dev/pty.*")
  )
  '' else ''
  (allow file-read* file-write*
      (literal "/dev/tty")
  )
  ''}

  ;; System Paths (Read + Exec)
  ${allowPaths "allow file-read* process-exec" systemPaths}

  ;; Nix Store
  ${optionalString cfg.features.nix ''
  (allow file-read* process-exec
      (subpath "/nix/store")
      (subpath "/var/nix")
      (subpath "/etc/nix")
  )
  ''}

  ;; Network
  ${optionalString (cfg.features.network || cfg.cli.unrestrictedNetwork) ''
  (allow network*)
  (allow system-socket)
  ''}

  ;; Temp
  ${optionalString cfg.features.tmp ''
  (allow file-read* file-write*
      (subpath "/tmp")
      (subpath "/private/tmp")
      (subpath "/var/folders")
      (subpath "/private/var/folders")
  )
  ''}

  ;; Unrestricted Filesystem
  ${optionalString cfg.cli.unrestrictedFilesystem ''
  (allow file-read* file-write* process-exec (subpath "/"))
  ''}
''
