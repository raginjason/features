# Dev Container Features: yadm

This repository contains a devcontainer feature for installing [yadm (Yet Another Dotfiles Manager)](https://yadm.io/).

## Features

### `yadm`

Installs yadm and optionally clones a dotfiles repository.

**Example Usage:**

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/raginjason/features/yadm:1": {
            "repositoryUrl": "https://github.com/username/dotfiles.git"
        }
    }
}
```

See the [yadm feature README](./src/yadm/README.md) for more details.

## Repository Structure

```
├── src
│   └── yadm
│       ├── devcontainer-feature.json
│       ├── install.sh
│       └── README.md
├── test
│   └── yadm
│       ├── test.sh
│       └── scenarios.json
└── .github
    └── workflows
        └── release.yaml
```

## Development

This repository follows the [devcontainer Feature distribution specification](https://containers.dev/implementors/features-distribution/).

### Testing Locally

You can test the feature locally by:

1. Building a devcontainer with the feature
2. Running the test script manually

### Publishing

Features are automatically published to GitHub Container Registry when changes are pushed to the main branch via the GitHub Actions workflow.

## License

This project is licensed under the MIT License.
