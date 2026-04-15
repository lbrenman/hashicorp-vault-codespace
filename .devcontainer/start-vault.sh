#!/bin/bash
set -e

echo "Installing HashiCorp Vault..."
wget -q -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update -qq && sudo apt-get install -y vault > /dev/null

echo "Starting Vault in dev mode..."
vault server -dev \
  -dev-root-token-id="root" \
  -dev-listen-address="0.0.0.0:8200" \
  > /tmp/vault.log 2>&1 &

echo "Waiting for Vault to be ready..."
sleep 3

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "Bootstrapping userpass auth and demo user..."
vault auth enable userpass 2>/dev/null || true
vault policy write demo-policy /workspaces/$(basename $PWD)/policies/demo-policy.hcl
vault write auth/userpass/users/demo \
  password="demo1234" \
  policies="demo-policy"

echo ""
echo "✅ Vault is running!"
echo "   UI:       http://localhost:8200/ui"
echo "   Token:    root"
echo "   Userpass: demo / demo1234"
