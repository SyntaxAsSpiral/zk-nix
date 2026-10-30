# Adds z and zi; cd stays plain. zoxide has no config file, only _ZO_* variables.
_: {
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };
}
