{ config, lib, ... }:

{
  # SSH config + keys + known_hosts written via activation script.
  # programs.ssh and home.file produce nix-store symlinks with 777 perms,
  # which SSH rejects. Writing directly is the only reliable fix.
  home.activation.sshSetup = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # SSH config — real file, correct perms
    cat > ~/.ssh/config << 'EOF'
Host *
  SendEnv TERM_PROGRAM
EOF
    chmod 600 ~/.ssh/config

    # SSH known_hosts — declarative mesh + github keys
    cat > ~/.ssh/known_hosts << 'EOF'
nxiz ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSJRTFHGmC5ivsPBhK3N5tfl5gwnPJsUV2ND/6W1XD0
adeck ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0+Uz+AZSjNl5NexhDFCvkN9U6Ee0dryJVYHsNaOPYY
zrrh ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOAByuEx9EVRqcy/FffrzET6+uRRL7JLS4WG+wGx9uyz
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
EOF
    chmod 644 ~/.ssh/known_hosts

    # SSH keys from secrets/ — copy into ~/.ssh with enforced perms.
    # Symlinking to repo-managed files can inherit 0644 and SSH rejects the key.
    SECRETS_DIR="$(readlink -f /etc/nixos/secrets 2>/dev/null || echo "")"
    if [ -n "$SECRETS_DIR" ] && [ -f "$SECRETS_DIR/id_ed25519" ]; then
      rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
      install -m 600 "$SECRETS_DIR/id_ed25519" ~/.ssh/id_ed25519
      if [ -f "$SECRETS_DIR/id_ed25519.pub" ]; then
        install -m 644 "$SECRETS_DIR/id_ed25519.pub" ~/.ssh/id_ed25519.pub
      fi
    fi
  '';

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };
}
