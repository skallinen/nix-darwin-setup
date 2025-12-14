# Hybrid macOS & NixOS Setup Guide

This guide documents the setup and maintenance of the hybrid development environment consisting of a **macOS Host** (using Home Manager) and a **NixOS VM** (running via UTM).

## 1. Architecture Overview
- **Host**: macOS with Home Manager.
- **VM**: NixOS running in UTM (ARM64).
- **Configuration Hub**: `~/nix-config` (Git Repository).
- **Authentication**: 
  - **Standard**: 1Password SSH Agent on Host, forwarded to VM.
  - **Fallback**: Local VM SSH Keys + Environment Variables (see Section 6).

## 2. Directory Structure
| Path | Environment | Description |
| :--- | :--- | :--- |
| `~/nix-config` | Host & VM | **System Config**. Git repository containing system Nix flakes (Darwin/NixOS). NO Emacs config. |
| `~/.config/emacs` | Host & VM | **Emacs Config**. Separate Git repository (`git@github.com:skallinen/emacs.git`) containing `init.el` and `myinit.org`. |

## 3. Emacs Synchronization Workflow
The Emacs configuration is managed in its own dedicated Git repository (`~/.config/emacs`).

### Host (Development)
1. **Edit** source: `~/.config/emacs/myinit.org`.
2. **Verify** locally: Restart Emacs or run batch check.
3. **Commit & Push**: `git -C ~/.config/emacs push origin main`.

### VM (Sync)
1. **SSH** into VM: `ssh vm`.
2. **Pull** changes: `git -C ~/.config/emacs pull`.
3. **Verify**: Run `emacs --batch -l ~/.config/emacs/init.el`.

## 4. SSH & Git Authentication (Standard Mode)
The VM does NOT store private SSH keys. It uses **SSH Agent Forwarding** to use the Host's 1Password keys.

### Host Configuration (`~/.ssh/config`)
Ensure the VM block enables agent forwarding and points to the 1Password socket:

```ssh
Host vm
  HostName 192.168.64.5
  User sakalli
  ForwardAgent yes
  # Point to your local 1Password agent socket
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

### VM Verification
To verify authentication is working inside the VM:
```bash
ssh vm "ssh-add -l"
```
*Successfully listed keys mean Git operations (clone/push/pull) will work.*

## 5. Verification Commands
Use these commands to validate the environment after changes.

**Check Emacs Startup (Headless):**
```bash
emacs --batch -l ~/.config/emacs/init.el --eval '(setq debug-on-error t)'
```

**Check Git Access (VM):**
```bash
ssh vm "git -C ~/nix-config remote -v"
```

## 6. Temporary Fallback Mode (No 1Password)
This mode allows Emacs and Git to function without the 1Password CLI/Agent.

### 6.1 Emacs Secrets
- **Mechanism**: `srk/op-bypass-1password` variable in `myinit.org` forces lookup from Environment Variables.
- **Usage**: Export secrets before starting Emacs.
    ```bash
    export OPENAI_API_KEY="sk-..."
    export ANTHROPIC_API_KEY="sk-..."
    emacs
    ```

### 6.2 Git Authentication
- **Mechanism**: Use VM's local SSH key instead of forwarding.
- **Setup**: Add VM public key to GitHub (`~/.ssh/id_ed25519.pub`).
- **Usage**: Standard `git pull`/`push` commands will use the local key automatically if agent forwarding is absent/fails.

### 6.3 Reversion
To restore strict 1Password reliance:
1. Remove the "Temporary 1Password Bypass" block from `~/.config/emacs/myinit.org`.
2. Commit and Sync.
