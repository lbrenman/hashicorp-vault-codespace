# HashiCorp Vault in GitHub Codespaces

A ready-to-run HashiCorp Vault development environment using GitHub Codespaces, with userpass authentication enabled out of the box.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/lbrenman/hashicorp-vault-codespace)

---

## What's Included

- HashiCorp Vault running in **dev mode** on port `8200`
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

| Method       | Value              |
|--------------|--------------------|
| Root Token   | `root`             |
| Username     | `demo`             |
| Password     | `demo1234`         |
| Vault URL    | `http://localhost:8200` |

> ⚠️ These are dev-mode credentials only. Never use these in production.

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

## Notes

- Vault runs in **dev mode** — all data is in-memory and lost when the Codespace stops
- The root token should only be used for initial setup; use userpass + client tokens for everything else
- To persist secrets across restarts, consider integrating an external storage backend (PostgreSQL, Consul, etc.)
