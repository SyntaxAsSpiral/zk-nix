{ ... }:

{
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/jolt 0755 - - -"
  ];

  # Background recorder for battery/energy history (tracks the 80% charge
  # cap behavior). `jolt daemon start` runs as a plain foreground process
  # and never installs a unit on NixOS, so we own the unit here.
  systemd.user.services.jolt-daemon = {
    Unit.Description = "Jolt battery/energy history daemon";
    Service = {
      ExecStart = "/run/current-system/sw/bin/jolt daemon start";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.configFile."jolt/config.toml".text = ''
    appearance = "dark"
    theme = "nord"
    refresh_ms = 2000
    show_graph = true
    graph_metric = "merged"
    process_count = 50
    energy_threshold = 0.5
    merge_mode = true
    transparent_background = false
    forecast_window_secs = 300
    excluded_processes = []
    log_level = "info"

    [history]
    background_recording = true
    sample_interval_secs = 60
    retention_raw_days = 30
    retention_hourly_days = 180
    retention_daily_days = 0
    retention_sessions_days = 90
    max_database_mb = 500

    [units]
    energy = "wh"
    temperature = "celsius"
    data_size = "si"
  '';
}
