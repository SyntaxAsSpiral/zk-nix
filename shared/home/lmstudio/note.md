There are two versions of LM Studio: the full GUI and llmster. llmster is bundled in the GUI. There is no separate repo. If you install the GUI, you can't use llmster alone. `.lmstudio/settings.json` has a field `cliInstalled` that seems to determine whether standalone llmster works. If the full LM Studio package is installed and the GUI is not running, `lms daemon` does not use the correct runtime. On nxiz, with the GUI not running, `lms runtime survey` returns an error.

Full GUI: https://lmstudio.ai/download/latest/linux/x64?format=AppImage

llmster CLI: `curl -fsSL https://lmstudio.ai/install.sh | bash`

On the mesh, nxiz and zrrh have the full client installed.
adeck has the headless CLI.

Issues:

- Headless llmster is not in nixpkgs.
- The custom derivation installs llmster on adeck and does not pick up the GPU through the Vulkan runtime, so it is not the correct CLI tool.
- Fixing the environment so the install script runs works, then requires manual updating. New builds have needed `libatomic`.

Current state:

- Vulkan is installed and selected on adeck (`lms runtime ls`).
- `lms runtime survey` shows the same error nxiz or zrrh shows when the GUI is not running.
- adeck should not need the GUI. It is a headless llmster install.
- adeck has a GPU, and `lms runtime survey` works when the CLI is installed correctly. 
