# Host Replication Guide: Setting up "Host B"

This guide details how to configure a new Mac to host your NixOS VM environment, including UTM settings, file sharing, and the "Reverse SSH" 1Password tunnel.

## 1. File & Data Transfer
Copy the following from Host A to Host B:
1.  **The VM Image**: `NixOS.utm` (Stop the VM first!).
    - Location: `~/Library/Containers/com.utmapp.UTM/Data/Documents/` (or wherever you saved it).
2.  **Configuration Repo**: `~/nix-config` (git clone or copy).
3.  **Shared Data**: `~/common` (if this is separate from config).
    - *Note: Ensure your `~/nix-config` is committed and pushed upstream so you can just clone it.*

## 2. UTM Configuration (Host B)
Import `NixOS.utm` into UTM on the new Mac. Verify these settings:

- **Network**:
    - Mode: **Shared Network**.
    - *Note: This ensures the Host is reachable at `192.168.64.1`.*
- **Sharing**:
    - Directory Share Mode: **VirtFS**.
    - Path: Select your `~/common` folder on Host B.
    - *Note: The VM expects this mount with the tag `share`.*
- **System**:
    - Architecture: `aarch64` (Apple Silicon).
    - RAM: 12GB (Match source).

## 3. macOS Host Configuration
The VM relies on the Host for secrets and networking.

### A. 1Password Setup (The "Server")
1.  **Install 1Password 8** & **CLI (`op`)**.
    - CLI must be at `/opt/homebrew/bin/op`.
2.  **Integration**: Settings > Developer > Check "Integrate with 1Password CLI".
3.  **Auth**: Run `op signin` in Terminal to ensure biometrics work.

### B. Reverse SSH Access
The VM needs to SSH *into* the Host to trigger `op`.
1.  **System Settings > General > Sharing**.
2.  Enable **Remote Login**.
3.  **Authorize VM Key**:
    - Get VM key: `cat ~/.ssh/id_ed25519.pub` (from inside VM).
    - Add to Host: `~/.ssh/authorized_keys`.
    - Ensure permissions: `chmod 600 ~/.ssh/authorized_keys`.

### C. Fonts (For GUI Emacs)
If you run Emacs on the Host:
1.  Install `all-the-icons` fonts:
    - Run `M-x all-the-icons-install-fonts` in Emacs, or install via Homebrew/download.

## 4. Verification
1.  Boot the VM.
2.  **Check Mounts**:
    - SSH in (`ssh vm`).
    - `ls -l ~/common`. It should show the Host's files.
3.  **Check 1Password**:
    - Run `host-op item list`.
    - Should prompt for TouchID on Host, then list items in VM.

## 5. Troubleshooting
- **Network**: If `192.168.64.1` is unreachable, check UTM IP settings.
- **Sharing**: If `~/common` is empty, check `sudo mount | grep virtio` in VM to see if `share` tag failed.
