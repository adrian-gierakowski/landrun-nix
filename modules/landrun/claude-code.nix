{ lib, config, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    darwin.extraSandboxProfile = ''
      (allow process-exec)
      (allow process-fork)
      (allow process-info* (target same-sandbox))
      (allow signal (target same-sandbox))
      (allow mach-priv-task-port (target same-sandbox))

      (allow sysctl-read
          (sysctl-name "hw.activecpu")
          (sysctl-name "hw.busfrequency_compat")
          (sysctl-name "hw.byteorder")
          (sysctl-name "hw.cacheconfig")
          (sysctl-name "hw.cachelinesize_compat")
          (sysctl-name "hw.cpufamily")
          (sysctl-name "hw.cpufrequency_compat")
          (sysctl-name "hw.cputype")
          (sysctl-name "hw.l1dcachesize_compat")
          (sysctl-name "hw.l1icachesize_compat")
          (sysctl-name "hw.l2cachesize_compat")
          (sysctl-name "hw.l3cachesize_compat")
          (sysctl-name "hw.logicalcpu_max")
          (sysctl-name "hw.machine")
          (sysctl-name "hw.memsize")
          (sysctl-name "hw.ncpu")
          (sysctl-name "hw.pagesize")
          (sysctl-name "hw.pagesize_compat")
          (sysctl-name "hw.physicalcpu_max")
          (sysctl-name "hw.tbfrequency_compat")
          (sysctl-name "kern.hostname")
          (sysctl-name "kern.maxfilesperproc")
          (sysctl-name "kern.osproductversion")
          (sysctl-name "kern.osrelease")
          (sysctl-name "kern.ostype")
          (sysctl-name "kern.osversion")
          (sysctl-name "kern.secure_kernel")
          (sysctl-name "kern.version")
      )

      (allow file-ioctl file-read-metadata file-read-data file-write-data  (literal "/dev/dtracehelper"))
      (allow file-ioctl file-read-metadata file-read-data file-write-data
        (require-all
          (literal "/dev/null")
          (vnode-type CHARACTER-DEVICE)
        )
      )

      (allow pseudo-tty)

      (allow mach-lookup
          (global-name "com.apple.sysmond")
          (global-name "com.apple.FSEvents")
          (global-name "com.apple.SystemConfiguration.DNSConfiguration")
      )

      (allow mach-lookup
        (global-name "com.apple.audio.systemsoundserver")
        (global-name "com.apple.distributed_notifications@Uv3")
        (global-name "com.apple.FontObjectsServer")
        (global-name "com.apple.fonts")
        (global-name "com.apple.logd")
        (global-name "com.apple.lsd.mapdb")
        (global-name "com.apple.PowerManagement.control")
        (global-name "com.apple.system.logger")
        (global-name "com.apple.system.notification_center")
        (global-name "com.apple.trustd.agent")
        (global-name "com.apple.system.opendirectoryd.libinfo")
        (global-name "com.apple.system.opendirectoryd.membership")
        (global-name "com.apple.bsd.dirhelper")
        (global-name "com.apple.securityd.xpc")
        (global-name "com.apple.coreservices.launchservicesd")
      )

      (allow mach-lookup
          (global-name "com.apple.SecurityServer")
          (global-name "com.apple.securityd")
          (global-name "com.apple.securityd.xpc")
      )
    '';
  };
}
