{pkgs, ...}: {
  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      pip # Python package installer
      virtualenv # Virtual environment tool
      setuptools # Package development library
      black # Code formatter
      flake8 # Linting tool
      mypy # Type checking
      requests # HTTP library for the Weather.py script
      playwright # Browser automation

      # From dev.nix
      pyyaml
      python-frontmatter
      python-dotenv
      gpustat
    ]))
  ];

  # Add pip configuration
  home.file.".config/pip/pip.conf".text = ''
    [global]
    user = true
  '';

  # Set environment variables for Python development
  home.sessionVariables = {
    PIP_USER = "1";
  };

  # Set Python path in environment
  home.sessionPath = ["${pkgs.python3}/bin"];
}
