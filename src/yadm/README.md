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
        "ghcr.io/raginjason/features/yadm:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repositoryUrl` | string | `""` | Git repository URL to clone with yadm. If provided, `yadm clone <url>` will be executed after installation. |

## Example with Repository URL

To add this feature to an existing devcontainer with your dotfiles:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/raginjason/features/yadm:1": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git"
        }
    }
}
```

More likely, you will want your yadm dotfiles to be used in every dev container via `dev.containers.defaultFeatures`, so add this to your `settings.json`:

```json
{
    "dev.containers.defaultFeatures": {
        "ghcr.io/raginjason/features/yadm:1": {
            "repositoryUrl": "https://github.com/your-user/your-dotfiles-repo.git"
        }
    }
}
```

## What does this feature do?

This feature:

1. **Installs yadm**: Downloads and installs the latest version of yadm from the official repository
2. **Clones dotfiles repository** (optional): If a `repositoryUrl` is provided, it will run `yadm clone <url>` to set up your dotfiles

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
