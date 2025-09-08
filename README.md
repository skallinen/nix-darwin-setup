# System config (nix-darwin + Home Manager)

Public flake for reproducing my macOS dev setup (Apple Silicon).

Outputs:
- Samis-MacBook-Air
- Gmtk-MacBook-Pro

What’s included
- nix-darwin 24.11 + Home Manager 24.11 on nixpkgs 24.11 (darwin)
- Homebrew via nix-darwin (formulae and casks)
- 1Password + 1password-cli (casks)
- Docker Desktop (cask: docker-desktop)
- Launch agent to auto-start Docker Desktop at login
- Zsh as default shell, macOS defaults, fonts
- Dev tools via Home Manager (ripgrep, git, awscli2, etc.)
- SSH configured to use 1Password SSH agent via IdentityAgent

Important
- No secrets in this repo. If you need runtime secrets, use 1Password or project-specific envs.
- ~/.ssh/config is managed by Home Manager; don’t edit it manually.
- Home Manager backs up conflicting files with the .backup extension automatically.

## Mac bootstrap

Prereqs
- Install Apple Command Line Tools: `xcode-select --install`
- Install Nix (daemon):
  - Determinate: `curl -L https://install.determinate.systems/nix | sh`
  - or Official: `sh <(curl -L https://nixos.org/nix/install) --daemon`

First apply (no local clone required)
- Replace `<owner>` with your GitHub user/org.
- Build and switch the Gmtk-MacBook-Pro config:
  - `nix build github:skallinen/nix-darwin-setup#darwinConfigurations.Gmtk-MacBook-Pro.system`
  - `./result/sw/bin/darwin-rebuild switch --flake github:skallinen/nix-darwin-setup#Gmtk-MacBook-Pro`

After the first switch
- Open 1Password, sign in. Enable Developer → “Use the SSH agent”.
- Sign into the App Store (for `mas` installs like GarageBand).
- Re-run the switch to finish installs if needed:
  - `darwin-rebuild switch --flake github:skallinen/nix-darwin-setup#Gmtk-MacBook-Pro`

Verify
- SSH with 1Password agent:
  - `ssh -G github.com | grep -i identityagent`
  - `ssh -T git@github.com`
- Homebrew and casks:
  - `brew --version`
  - `brew list --cask | sort`
- Docker Desktop present:
  - `/Applications/Docker.app`

Emacs config
- Clone your Emacs config repo to `~/.config/emacs` (kept separate from this repo):
  - `git clone git@github.com:<owner>/<emacs-repo>.git ~/.config/emacs`

## Existing Mac (Air)

Apply current host config
- `darwin-rebuild switch --flake ~/src/system-config#Samis-MacBook-Air`

SSH via 1Password (managed)
- The flake manages `~/.ssh/config` to use 1Password’s agent:
  - `IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"`

## Common tasks

Rebuild/switch commands (explicit):
- Mac 1 
  - darwin-rebuild switch --flake ~/src/system-config#Samis-MacBook-Air
- Mac 2 
  - darwin-rebuild switch --flake github:skallinen/nix-darwin-setup#Gmtk-MacBook-Pro

- Rebuild/switch: `darwin-rebuild switch --flake ~/src/system-config#<Host>`
- Update inputs: `nix flake update`
- Update and switch in one go:
  - `nix flake update && darwin-rebuild switch --flake ~/src/system-config#<Host>`

## Notes

- If a managed file already exists, Home Manager saves a backup like `file.backup` and replaces it.
- Hostname differences are handled per-output in `flake.nix` (inline module). No separate host files required.
- Docker Desktop is installed via Homebrew cask; if you previously installed it manually, uninstall it first.

## Troubleshooting

- If SSH fails to use 1Password, ensure the agent is enabled in 1Password and that `ssh -G github.com` shows an IdentityAgent path under the 1Password Group Containers directory.
- If `darwin-rebuild` reports files in the way, delete them or rely on backups (already enabled here) and re-run.


## Docker Desktop first run

On macOS the Docker daemon runs inside a Linux VM provided by Docker Desktop.
This repo installs Docker Desktop via Homebrew (cask: docker-desktop).

First-time setup (one-time):
- Log out/in to start Desktop, or run: `open -ga "Docker"`
  - If that fails, run: `open /Applications/Docker.app`
- In Docker Desktop, accept any prompts (install helper).
- This should set everything for Docker, if you cant run the hello world below, try in Troubleshoot, click “Install CLI tools”.
- Wait until the whale icon says “Docker Desktop is running”.
- Verify in a new terminal:
  - `command -v docker`
  - `docker context show` (should be `desktop-linux`)
  - `docker run --rm hello-world`

Notes:
- This flake sets DOCKER_CONTEXT=desktop-linux and auto-switches the docker context in zsh when appropriate.
- Do not install Docker via `brew install docker` (that’s CLI-only). Use the cask `docker-desktop`.

