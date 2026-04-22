ok there are two versions of lmstudio. full gui and llmster.  llmster is bundled in gui. there is no seperate repo.  but if you install gui, you can't use llmster alone. there is a field in .lmstudio/settings.json called "cliInstalled" that seems to determine whether you can use standalone llmster or not.  if you have full lmstudio package on your machine, and attempt to use lms daemon it will not use the correct runtime UNLESS you have gui running.  [Image #1]  right now on nxiz i do not have gui running, so `lms runtime survey` returns an error.

full gui: https://lmstudio.ai/download/latest/linux/x64?format=AppImage
llmster cli: curl -fsSL https://lmstudio.ai/install.sh | bash

On mesh I have full client installled on nxiz and zrrh.
I have headless cli on adeck. 

Issues:

- full client consistently fails to open with app launcher. this is happening in zrrh (noctalia qs) and nxiz (fsel?).`"x-scheme-handler/lmstudio" = "lm-studio.desktop";` in xdg.nix worked briefly. 
- headless llmster doesn't exist in nix pkgs. 
- custom derivation installs llmster on adeck but does not pick up adeck's gpu with vulkan runtime indicating that its not the correct cli tool.
- fixing env to run install script works but then requires manual updating. and new changes like `libatmoic` suddenly being needed. 
