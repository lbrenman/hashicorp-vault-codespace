#!/bin/bash
set -e

REPO_DIR="/workspaces/$(basename $PWD)"
DATA_DIR="/workspaces/vault-data"
INIT_FILE="$DATA_DIR/.vault-init"
CONFIG="$REPO_DIR/vault-config/vault.hcl"

export VAULT_ADDR='http://127.0.0.1:8200'

# ── Install Vault ────────────────────────────────────────────────────────────
if ! command -v vault &>/dev/null; then
  echo "Installing HashiCorp Vault..."
  wget -q -O- https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y vault > /dev/null
  echo "Vault installed."
fi

# ── Start Vault server ───────────────────────────────────────────────────────
mkdir -p "$DATA_DIR"

# Remove IPC_LOCK capability — Codespaces blocks it
sudo setcap cap_ipc_lock=-ep $(which vault) 2>/dev/null || true
export VAULT_DISABLE_MLOCK=true

echo "Starting Vault server (file storage)..."
vault server -config="$CONFIG" > /tmp/vault.log 2>&1 &
sleep 3

# ── Initialize (first run only) ─────────────────────────────────────────────
if [ ! -f "$INIT_FILE" ]; then
  echo "First run — initializing Vault..."
  vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > "$INIT_FILE"
  chmod 600 "$INIT_FILE"
  echo "Vault initialized. Init data saved to $INIT_FILE"
fi

# ── Unseal ───────────────────────────────────────────────────────────────────
UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' "$INIT_FILE")
ROOT_TOKEN=$(jq -r '.root_token' "$INIT_FILE")

echo "Unsealing Vault..."
vault operator unseal "$UNSEAL_KEY" > /dev/null

export VAULT_TOKEN="$ROOT_TOKEN"

# ── Bootstrap auth (first run only) ─────────────────────────────────────────
if ! vault auth list 2>/dev/null | grep -q "userpass"; then
  echo "Enabling userpass auth and creating demo user..."
  vault auth enable userpass
  vault policy write demo-policy "$REPO_DIR/policies/demo-policy.hcl"
  vault secrets enable -path=secret kv-v2
  vault write auth/userpass/users/demo \
    password="demo1234" \
    policies="demo-policy"
  echo "Bootstrap complete."
fi

# ── Write VAULT_TOKEN to shell profile so terminals pick it up ───────────────
grep -q "VAULT_ADDR" "$HOME/.bashrc" 2>/dev/null || \
  echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> "$HOME/.bashrc"
grep -q "VAULT_TOKEN" "$HOME/.bashrc" 2>/dev/null && \
  sed -i "s|^export VAULT_TOKEN=.*|export VAULT_TOKEN='$ROOT_TOKEN'|" "$HOME/.bashrc" || \
  echo "export VAULT_TOKEN='$ROOT_TOKEN'" >> "$HOME/.bashrc"

echo ""
echo "✅ Vault is running with persistent file storage!"
echo "   UI:         http://localhost:8200/ui"
echo "   Root Token: $ROOT_TOKEN"
echo "   Userpass:   demo / demo1234"
echo ""
echo "⚠️  The init file (unseal key + root token) is stored at:"
echo "   $INIT_FILE"
echo "   It is excluded from git via .gitignore."
