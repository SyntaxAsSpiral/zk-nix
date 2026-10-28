# Performance optimizations inspired by Garuda and CachyOS
{ pkgs, lib, config, ... }:

{
  options.my.performance.enable = lib.mkEnableOption "system-wide performance optimizations";

  config = lib.mkIf config.my.performance.enable {
    # 1. Process Scheduling: Ananicy-cpp + CachyOS rules
    # This automatically 'nices' games, compositors, and background tasks.
    services = {
      ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };

      # 2. Interrupt distribution: irqbalance
      # Distributes hardware interrupts across CPU cores for better responsiveness.
      irqbalance.enable = true;

      # 3. I/O Schedulers: udev rules
      # NVMe = none (hardware handles it)
      # SSD/eMMC = bfq (budget fair queueing)
      # Spinning disk = bfq
      udev.extraRules = ''
        # set scheduler for NVMe
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
        # set scheduler for SSD and eMMC
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
        # set scheduler for rotating disks
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '';
    };

    # 4. CPU Governor: powersave + balance_performance EPP (amd-pstate-epp)
    # Sustained all-core loads still reach full PPT-limited boost; saves
    # ~20W package power at idle/light load vs the performance governor.
    # (Measured on zrrh 7950X: 74W -> 51W idle; build clocks unchanged.)
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    systemd.services.amd-epp = {
      description = "Set AMD pstate energy_performance_preference";
      wantedBy = [ "multi-user.target" ];
      after = [ "cpufreq.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          echo balance_performance > "$f"
        done
      '';
    };

    # 5. Memory Management: zram + oomd
    # Better behavior under high load/low memory.
    zramSwap.enable = true;
    systemd.oomd = {
      enable = true;
      enableUserSlices = true;
    };

    # 6. Kernel tweaks: sysctl (Garuda defaults)
    boot.kernel.sysctl = {
      # Reduce swap tendency
      "vm.swappiness" = 10;
      # Increase max file descriptors
      "fs.file-max" = 2097152;
      # Network stack optimizations
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_max_syn_backlog" = 8192;
      "net.ipv4.tcp_max_tw_buckets" = 2000000;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_fin_timeout" = 10;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_keepalive_time" = 60;
      "net.ipv4.tcp_keepalive_intvl" = 10;
      "net.ipv4.tcp_keepalive_probes" = 6;
      "net.ipv4.tcp_mtu_probing" = 1;
    };
    # 7. Low-latency kernel params
    boot.kernelParams = [ "pcie_aspm=performance" ];
  };
}
