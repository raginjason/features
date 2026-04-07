# Plan: Refactor yadm Feature — Move Clone to postCreate

## Goal

Move `yadm clone` (and related setup) from `install.sh` (image build time) to a
`postCreateCommand` script so that dotfiles are written after named volumes are
mounted — specifically to support a devcontainer volume at `/home/vscode/.claude`.

## Background

Currently `install.sh` runs `yadm clone` at image build time, before any volumes
are mounted. If a devcontainer mounts a named volume over a path managed by yadm
(e.g. `/home/vscode/.claude`), the volume shadows the files yadm wrote during
build, so those dotfiles are never visible inside the container.

Moving the clone to `postCreateCommand` means it runs after volumes are mounted,
so yadm writes directly into the volume.

---

## Files to Change

- `src/yadm/install.sh` — remove clone/checkout/class/decrypt logic; keep binary install + write config + stage scripts
- `src/yadm/devcontainer-feature.json` — update `postCreateCommand` to point at new script; bump version to `1.1.0`
- `src/yadm/yadm-setup.sh` — new file: orchestrates clone, checkout, localClass, decrypt
- `src/yadm/yadm-decrypt.sh` — source `/usr/local/share/yadm-config` instead of reading flat file; self-gates on `DECRYPTONCLONE`

---

## Step-by-Step

### 1. Trim `install.sh`

Remove everything after the yadm binary installation. Specifically, remove:
- `yadm clone` invocation
- `yadm checkout $HOME` invocation
- `yadm config local.class` invocation
- The single-value flat file (`/usr/local/share/yadm-config-decrypt-on-clone`)

Keep:
- yadm binary download and placement at `/usr/local/bin/yadm`
- Version verification
- Writing `/usr/local/share/yadm-config` (see step 3)
- Staging helper scripts into `/usr/local/share/` (see step 3)

### 2. Create `src/yadm/yadm-setup.sh`

This script runs postCreate, after volumes are mounted. It sources
`/usr/local/share/yadm-config`, then mirrors the root/non-root user branching
from `install.sh` for clone, checkout, and class — then always calls
`yadm-decrypt.sh` (which self-gates on `DECRYPTONCLONE`).

```bash
#!/bin/bash
set -e

source /usr/local/share/yadm-config

REPOSITORY_URL="${REPOSITORYURL:-}"
LOCAL_CLASS="${LOCALCLASS:-}"
OVERWRITE_EXISTING="${OVERWRITEEXISTING:-false}"

if [ -n "${REPOSITORY_URL}" ]; then
    if [ "$(id -u)" = "0" ]; then
        if getent passwd 1000 > /dev/null 2>&1; then
            NON_ROOT_USER=$(getent passwd 1000 | cut -d: -f1)
            set +e
            su - "${NON_ROOT_USER}" -c "yadm clone '${REPOSITORY_URL}'"
            set -e
            if [ "${OVERWRITE_EXISTING}" = "true" ]; then
                su - "${NON_ROOT_USER}" -c "yadm checkout \$HOME"
            fi
            if [ -n "${LOCAL_CLASS}" ]; then
                su - "${NON_ROOT_USER}" -c "yadm config local.class '${LOCAL_CLASS}'"
            fi
            su - "${NON_ROOT_USER}" -c "yadm status"
        else
            echo "Warning: Running as root with no non-root user. Clone manually with: yadm clone ${REPOSITORY_URL}"
        fi
    else
        set +e
        yadm clone "${REPOSITORY_URL}"
        set -e
        if [ "${OVERWRITE_EXISTING}" = "true" ]; then
            yadm checkout "$HOME"
        fi
        if [ -n "${LOCAL_CLASS}" ]; then
            yadm config local.class "${LOCAL_CLASS}"
        fi
        yadm status
    fi
else
    echo "No repository URL provided. Clone manually with: yadm clone <repository-url>"
fi

/usr/local/share/yadm-decrypt.sh
```

### 3. Update `install.sh` to stage scripts and write config file

At the end of install.sh (after binary install), add:

```bash
# Stage postCreate scripts
cp "$(dirname "$0")/yadm-setup.sh" /usr/local/share/yadm-setup.sh
cp "$(dirname "$0")/yadm-decrypt.sh" /usr/local/share/yadm-decrypt.sh
chmod +x /usr/local/share/yadm-setup.sh /usr/local/share/yadm-decrypt.sh

# Persist feature options for postCreate
cat > /usr/local/share/yadm-config <<EOF
export REPOSITORYURL="${REPOSITORYURL}"
export OVERWRITEEXISTING="${OVERWRITEEXISTING}"
export LOCALCLASS="${LOCALCLASS}"
export DECRYPTONCLONE="${DECRYPTONCLONE}"
EOF
```

### 4. Update `yadm-decrypt.sh` to source `yadm-config`

Replace the flat-file read block:

```bash
DECRYPT_ON_CLONE="false"
if [ -f "/usr/local/share/yadm-config-decrypt-on-clone" ]; then
    DECRYPT_ON_CLONE=$(cat /usr/local/share/yadm-config-decrypt-on-clone)
fi
```

With:

```bash
if [ -f "/usr/local/share/yadm-config" ]; then
    source /usr/local/share/yadm-config
fi
DECRYPT_ON_CLONE="${DECRYPTONCLONE:-false}"
```

The rest of `yadm-decrypt.sh` (root/non-root branching, archive check, decrypt call) is unchanged.

### 5. Update `devcontainer-feature.json`

Change `postCreateCommand` from pointing at `yadm-decrypt.sh` to `yadm-setup.sh`,
and bump the version to `1.1.0`:

```json
"version": "1.1.0",
...
"postCreateCommand": "/usr/local/share/yadm-setup.sh"
```

---

## Testing Checklist

- [ ] Container builds without error (yadm binary installed, no clone attempted)
- [ ] `yadm` is available in PATH after build
- [ ] On first container create, `yadm clone` runs and dotfiles appear
- [ ] Named volume at `/home/vscode/.claude` (or any yadm-managed path) is populated correctly
- [ ] `overwriteExisting: true` correctly runs `yadm checkout $HOME`
- [ ] `localClass` is applied after clone
- [ ] `decryptOnClone: true` triggers GPG decrypt
- [ ] Rebuild container re-runs postCreate and re-clones cleanly

---

## Tradeoff Note

Dotfiles are no longer baked into the image layer — `yadm clone` now incurs a
network call at every `postCreate` (i.e. every new container or rebuild). For
personal dotfiles this is acceptable and arguably preferable (always fresh), but
note the change in behavior.
