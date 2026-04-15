# HashiCorp Vault in GitHub Codespaces

A ready-to-run HashiCorp Vault development environment using GitHub Codespaces, with userpass authentication enabled out of the box.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME)

---

## What's Included

- HashiCorp Vault running with **persistent file storage** on port `8200`
- Secrets survive Codespace stop/start — stored in `/workspaces/vault-data/` (persisted by Codespaces)
- Auto-unseal on every restart using the stored init file
- **Userpass auth** pre-configured with a demo user
- A sample **policy** scoped to `secret/data/demo/*`
- Vault UI accessible via forwarded port

---

## Quick Start

1. Click the **Open in GitHub Codespaces** button above
2. Wait for the Codespace to build and the startup script to finish (~1 min)
3. Open the **Ports** tab and click the link for port `8200` to open the Vault UI

---

## Credentials

| Method       | Value                                              |
|--------------|----------------------------------------------------|
| Root Token   | Dynamic — printed in terminal on startup           |
| Username     | `demo`                                             |
| Password     | `demo1234`                                         |
| Vault URL    | `http://localhost:8200`                            |

> ⚠️ The root token is generated at first init and stored in `/workspaces/vault-data/.vault-init`. Check your terminal output on startup to see it.

---

## Using the CLI

Environment variables are pre-set in the Codespace terminal:

```bash
# Check Vault status
vault status

# Log in as demo user (returns a client token)
vault login -method=userpass username=demo password=demo1234

# Store a secret
vault kv put secret/demo/myapp api_key="abc123"

# Read it back
vault kv get secret/demo/myapp
```

---

## Using the REST API

```bash
# Authenticate and capture the token
TOKEN=$(curl -s -X POST http://127.0.0.1:8200/v1/auth/userpass/login/demo \
  -d '{"password":"demo1234"}' | jq -r '.auth.client_token')

# Write a secret
curl -s -X POST http://127.0.0.1:8200/v1/secret/data/demo/myapp \
  -H "X-Vault-Token: $TOKEN" \
  -d '{"data":{"api_key":"abc123"}}'

# Read a secret
curl -s http://127.0.0.1:8200/v1/secret/data/demo/myapp \
  -H "X-Vault-Token: $TOKEN" | jq .
```

---

## Project Structure

```
.
├── .devcontainer/
│   ├── devcontainer.json     # Codespace configuration
│   └── start-vault.sh        # Vault install + bootstrap script
├── policies/
│   └── demo-policy.hcl       # Sample Vault policy
├── .gitignore
└── README.md
```

---

## Adding More Users

```bash
vault write auth/userpass/users/newuser \
  password="newpassword" \
  policies="demo-policy"
```

## Adding More Policies

Create a new `.hcl` file in `policies/` and apply it:

```bash
vault policy write my-policy policies/my-policy.hcl
```

---

## Persistence

Vault data is stored in `/workspaces/vault-data/`, which GitHub Codespaces persists across stop/start cycles. On every restart, the startup script:

1. Starts the Vault server with the file storage config
2. Reads the unseal key from `/workspaces/vault-data/.vault-init`
3. Automatically unseals Vault
4. Skips bootstrapping (userpass/policies already exist)

The `.vault-init` file contains the unseal key and root token. It is excluded from git via `.gitignore` — **never commit it.**

> ⚠️ If you delete the Codespace entirely, `vault-data/` is lost and you'll need to reinitialize from scratch.

## Notes

- The root token is dynamically generated at init time and written to your terminal by the startup script
- The root token should only be used for initial setup; use userpass + client tokens for day-to-day access
- `jq` is required by the startup script and is pre-installed in the base Codespace image
