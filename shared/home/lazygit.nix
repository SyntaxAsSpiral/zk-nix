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
      gui = {
        nerdFontsVersion = "3";
        # Off also drops the Donate and Ask Question links from the bottom line.
        mouseEvents = false;
        portraitMode = "auto";
        # Stack into one column at 50 columns or narrower, once 20 rows tall.
        portraitModeAutoMaxWidth = 50;
        portraitModeAutoMinHeight = 20;
      };
    };
  };
}
