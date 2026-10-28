_:
{
  programs.lazygit = {
    enable = true;
    settings = {
      disableStartupPopups = true;
      notARepository = "skip";
      promptToReturnFromSubprocess = false;
      update.method = "never";
      git.parseEmoji = true;
      gui.nerdFontsVersion = "3";
    };
  };
}
