{
  systemd.user.services.festin = {
    Unit = {
      Description = "Festin kitchen on adeck";
      After = [
        "network-online.target"
        "tailscaled.service"
      ];
    };

    Install.WantedBy = [ "default.target" ];

    Service = {
      WorkingDirectory = "/mnt/echo/festin";
      Restart = "on-failure";
      RestartSec = 3;
      # User services do not inherit a login PATH. llama-tts and ffmpeg are
      # in the system profile; git (nix develop) is in the user profile.
      Environment = [
        "PATH=/run/wrappers/bin:/etc/profiles/per-user/zk/bin:/run/current-system/sw/bin"
        "FESTIN_TTS_MODEL=/home/zk/.lmstudio/models/ggml-org/Qwen3-TTS-12Hz-1.7B-Base-GGUF/Qwen3-TTS-12Hz-1.7B-Base-Q4_K_M.gguf"
        "FESTIN_TTS_PROJECTOR=/home/zk/.lmstudio/models/ggml-org/Qwen3-TTS-12Hz-1.7B-Base-GGUF/mmproj-Qwen3-TTS-12Hz-1.7B-Base-bf16.gguf"
        "FESTIN_VOICE_REFERENCE=/mnt/echo/festin/data/voice-ref/babette-v1-10s.wav"
        "FESTIN_MODEL_KEY_FILE=/run/secrets/festin-openrouter-api-key"
      ];
      ExecStart = "/run/current-system/sw/bin/nix --extra-experimental-features \"nix-command flakes\" develop /mnt/echo/festin -c python -m festin.server data/kitchen.db --host 127.0.0.1 --port 8879 --inbox-url https://adeck.tail293e98.ts.net:8443 --web web/dist";
    };
  };
}
