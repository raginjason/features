# Yet Another Dotfiles Manager (yadm)

**Feature ID:** `yadm`

**Version:** `1.0.0`

**Description:** Install yadm (Yet Another Dotfiles Manager) for managing dotfiles in a git repository. This feature exists because the way VS Code dotfiles clones repositories is not usable in the way that yadm expects. As such, this feature should be used *instead of* the `dotfiles.installCommand`, `dotfiles.repository`, and `dotfiles.targetPath` settings.

## Usage

To simply install yadm in an existing devcontainer:

 ```json
 {
     "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
     "features": {
        "ghcr.io/raginjason/features/yadm": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repositoryUrl` | string | `""` | The URL of the git repository to clone with yadm. If specified, `yadm clone <repositoryUrl>` will be executed after yadm is installed. |
| `localClass`    | string | `""` | Optional class name for the local machine. If set, runs `yadm config local.class <localClass>` to enable machine-specific configuration. |
| `overwriteExisting` | boolean | `false` | If true, existing files will be overwritten when cloning the dotfiles repository using `yadm checkout $HOME`. |
| `decryptOnClone` | boolean | `false` | If true, runs `yadm decrypt` after cloning when an encrypted yadm archive exists (typically `$HOME/.local/share/yadm/archive`). This is intended for GPG recipient-based yadm encryption. |

## Example with Repository URL

To add this feature to an existing devcontainer with your dotfiles:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/raginjason/features/yadm": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git",
            "overwriteExisting": true
        }
    }
}
```

More likely, you will want your yadm dotfiles to be used in every dev container via `dev.containers.defaultFeatures`, so add this to your `settings.json`:

```json
{
    "dev.containers.defaultFeatures": {
        "ghcr.io/raginjason/features/yadm": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git",
            "overwriteExisting": true
        }
    }
}
```

Or with a `local.class` as well

```json
{
    "dev.containers.defaultFeatures": {
        "ghcr.io/raginjason/features/yadm": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git",
            "localClass": "Work",
            "overwriteExisting": true
        }
    }
}
```

## Encrypted dotfiles (yadm + GPG)

yadm supports encrypting selected files into an archive committed to your dotfiles repo. To restore encrypted files on a new machine/container, you must run `yadm decrypt`. This feature can do that automatically when `decryptOnClone` is enabled.

**Important:** The decrypt operation runs during the **postCreate** container lifecycle phase (after feature installation), ensuring that GPG keys and agents are available. This means encryption/decryption setup should be configured before or during the postCreate phase.

Recommended setup is **asymmetric (GPG recipient) encryption** so you don't need to pass a password into the container. See [yadm encryption documentation](https://yadm.io/docs/encryption#).

Example feature config:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/raginjason/features/yadm": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git",
            "decryptOnClone": true,
            "overwriteExisting": true
        }
    }
}
```

Notes:

- The encrypted archive is typically stored at `$HOME/.local/share/yadm/archive`. If it doesn't exist, the decrypt operation will be skipped even if `decryptOnClone` is true.
- **Timing:** The decrypt operation runs during the `postCreateCommand` lifecycle phase, after container creation when GPG services are typically available.
- **GPG Setup:** Ensure your GPG identity is available inside the devcontainer before the decrypt operation. This can be done via GPG agent forwarding, environment variables, or devcontainer setup scripts.
- **Troubleshooting:** If decryption fails, check that GPG keys are properly configured and available in the container environment. You can manually run `yadm decrypt` to test GPG setup.

## What does this feature do?

This feature:

1. **Installs yadm**: Downloads and installs the latest version of yadm from the official repository
2. **Clones dotfiles repository** (optional): If a `repositoryUrl` is provided, it will run `yadm clone <url>` to set up your dotfiles
3. **Overwrites existing files** (optional): If `overwriteExisting` is set to true, it will run `yadm checkout $HOME` after cloning to overwrite any existing files with versions from your dotfiles repository
4. **Handles localClass option** (optional): If the `localClass` option is specified, it will run `yadm config local.class <localClass>` to set a custom class for your local machine. This allows you to apply machine-specific configuration files based on the class name.
5. **Decrypts encrypted files** (optional): If `decryptOnClone` is enabled and an encrypted archive exists, it will run `yadm decrypt` during the postCreate lifecycle phase when GPG services are available.

## About yadm

yadm (Yet Another Dotfiles Manager) is a tool for managing a collection of files known as dotfiles. It's a git wrapper that makes it easy to store configuration files in a git repository and deploy them across multiple machines.

Key features of yadm:
- Uses a bare git repository for tracking dotfiles
- Supports encryption of sensitive files
- Can run bootstrap scripts
- Handles alternate files for different systems
- Supports Jinja2 templates

## Usage after installation

After the feature is installed, you can use yadm commands like:

```bash
# If you didn't provide a repository URL during installation
yadm clone https://github.com/username/dotfiles.git

# Check status
yadm status

# Add files
yadm add ~/.bashrc
yadm commit -m "Add bashrc"
yadm push

# List tracked files
yadm list
```

## Documentation

For more information about yadm, visit:
- [Official yadm documentation](https://yadm.io/)
- [yadm GitHub repository](https://github.com/TheLocehiliosan/yadm)

## Notes

- If running as root during container build, the feature will attempt to run `yadm clone` as a non-root user (UID 1000) if available
- You may need to configure git user settings before pushing changes:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```
