# Portable NixOS-WSL CLI environment

This repository configures one reusable NixOS-WSL command-line system. It has
no desktop environment or graphical applications.

## Included tools

- Zsh, Starship, direnv with nix-direnv, Git, GitHub CLI, tmux
- ripgrep, fd, fzf, zoxide, bat, eza, btop, tree, jq, fastfetch
- Helix with language servers and formatters
- Codex CLI, uv, kubectl, k9s, Teleport
- rootless Podman with a Docker-compatible command

Distrobox is intentionally absent.

## Layout

- flake.nix wires Nixpkgs, NixOS-WSL, and Home Manager.
- configuration.nix defines the WSL system, account, Nix, and Podman.
- home.nix defines the command-line user environment.
- helix.nix defines editor and language-server settings.
- tests/configuration.sh evaluates the portable configuration invariants.

The only flake output is nixosConfigurations.wsl.

## Fresh installation

Start with an imported official NixOS-WSL distribution named NixOS. Open it as
the initial nixos user and clone the repository with temporary Git:

~~~bash
nix-shell --extra-experimental-features 'nix-command flakes' -p git \
  --run 'git clone https://github.com/Itterum/nixos-config.git ~/nixos-config'

cd ~/nixos-config

nix --extra-experimental-features 'nix-command flakes' \
  build --no-link \
  'path:.#nixosConfigurations.wsl.config.system.build.toplevel'
~~~

The build must succeed before the account changes. Exit the WSL shell. In
Windows PowerShell, stop the distribution and reopen it as root:

~~~powershell
wsl.exe --terminate NixOS
wsl.exe -d NixOS -u root
~~~

In the root shell, record the current generation and make a dated, root-owned
copy of the original configuration before changing the account:

~~~bash
backup="/root/nixos-backup-$(date -u +%Y%m%dT%H%M%SZ)"
cp -a /etc/nixos "$backup"

{
  date -u
  id nixos
  readlink -f /run/current-system
  nixos-rebuild list-generations
} > "$backup/migration-state.txt"

printf 'Recovery backup: %s\n' "$backup"
~~~

Keep the printed path. Then rename the existing UID 1000 account, move its
home, and activate the previously built configuration:

~~~bash
usermod --login itterum nixos
usermod --home /home/itterum --move-home itterum

id itterum

nixos-rebuild switch \
  --flake path:/home/itterum/nixos-config#wsl \
  --extra-experimental-features 'nix-command flakes'
~~~

Exit, restart once more, and open the normal default session:

~~~powershell
wsl.exe --terminate NixOS
wsl.exe -d NixOS
~~~

The session should now report:

~~~bash
whoami
# itterum

printf '%s\n' "$HOME"
# /home/itterum
~~~

The configuration deliberately preserves system.stateVersion 25.05. Do not
change it when moving the configuration to a newer computer.

## GitHub SSH key

To copy the current Windows Ed25519 key into WSL, run these commands as the
Linux user. They do not modify the Windows source files:

~~~bash
install -d -m 0700 ~/.ssh
install -m 0600 /mnt/c/Users/itterum/.ssh/id_ed25519 ~/.ssh/id_ed25519
install -m 0644 /mnt/c/Users/itterum/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub

cmp -s /mnt/c/Users/itterum/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub &&
  printf 'Public key copy verified\n'
ssh-keygen -lf /mnt/c/Users/itterum/.ssh/id_ed25519.pub
ssh-keygen -lf ~/.ssh/id_ed25519.pub
ssh -T git@github.com
~~~

A successful GitHub authentication says that authentication succeeded and that
GitHub does not provide shell access. The SSH command commonly exits with
status 1 despite successful authentication.

Switch this checkout from HTTPS to SSH:

~~~bash
git remote set-url origin git@github.com:Itterum/nixos-config.git
git ls-remote origin HEAD
~~~

## Apply changes

Edit the checkout in the Linux filesystem, validate it, then activate it:

~~~bash
cd ~/nixos-config

bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link \
  'path:.#nixosConfigurations.wsl.config.system.build.toplevel'

sudo nixos-rebuild switch --flake path:.#wsl
~~~

Update pinned dependencies intentionally:

~~~bash
cd ~/nixos-config
nix flake update
bash tests/configuration.sh
sudo nixos-rebuild switch --flake path:.#wsl
~~~

## Maintenance and recovery

List and roll back NixOS generations:

~~~bash
sudo nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback
~~~

Run garbage collection manually:

~~~bash
sudo nix-collect-garbage --delete-older-than 14d
nix store optimise
~~~

If the default account cannot start, open a root recovery shell from Windows:

~~~powershell
wsl.exe -d NixOS -u root
~~~

The migration procedure keeps a dated copy of the previous /etc/nixos under
/root. If activation fails after the account rename, open the root recovery
shell, restore the original account name, and switch to the backed-up flake:

~~~bash
usermod --login nixos itterum
usermod --home /home/nixos --move-home nixos

nixos-rebuild switch \
  --flake path:/root/nixos-backup-YYYYMMDDTHHMMSSZ#nixos \
  --extra-experimental-features 'nix-command flakes'
~~~

Replace the timestamp with the printed backup path.
