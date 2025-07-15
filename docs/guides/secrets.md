# Secrets Management

## Overview

Secrets are managed using [agenix](https://github.com/ryantm/agenix) for encryption at rest.

## Current Secrets

Located in `/secrets/`:

- `chatgpt_key.age` - ChatGPT CLI authentication
- `cloudflare_dns_token.age` - Let's Encrypt DNS challenges
- `grist_api_key.age` - Grist spreadsheet API
- `grist_proxy_auth.age` - Grist proxy authentication
- `hass_server.age` - Home Assistant server URL
- `hass_token.age` - Home Assistant API token
- `tailscale_auth_key.age` - Tailscale pre-authentication

## Working with Secrets

### Method 1: Direct Editing (Recommended)

```bash
# Enter nix develop shell for agenix
nix develop

# Create/edit a secret (opens $EDITOR)
agenix -e secrets/new_secret.age
# Type your secret content, save and exit

# Decrypt a secret (requires your SSH key)
agenix -d secrets/existing_secret.age
```

### Method 2: From secrets.json (Legacy)

If you maintain secrets in `secrets.json` for convenience:

```bash
# Extract from JSON and encrypt
jq -r '.my_secret' secrets.json | agenix -e secrets/my_secret.age
```

## Adding a New Secret

1. **Create the encrypted secret**:

   ```bash
   nix develop
   agenix -e secrets/new_secret.age
   # Enter secret content in editor
   ```

2. **Add to secrets.nix**:

   ```nix
   "secrets/new_secret.age".publicKeys = allUsers ++ allSystems;
   ```

3. **Reference in configuration**:

   ```nix
   age.secrets.new_secret = {
     file = ../secrets/new_secret.age;
     owner = "service-user";  # optional
     mode = "0400";          # optional
   };
   ```

4. **Use in service**:
   ```nix
   services.example = {
     environmentFile = config.age.secrets.new_secret.path;
   };
   ```

### Secret File Formats

For environment files:

```bash
# secrets/service_env.age content:
API_KEY=your-actual-api-key-here
DATABASE_URL=postgresql://user:pass@host/db
```

For single values:

```bash
# secrets/api_key.age content:
your-actual-api-key-here
```

## Decrypting Secrets

To view a secret (requires your SSH key to be in `secrets.nix`):

```bash
nix develop
agenix -d secrets/secret_name.age
```

## Adding a New Host

```bash
# 1. Get host's SSH key
ssh root@hostname 'cat /etc/ssh/ssh_host_ed25519_key.pub'

# 2. Add to secrets.nix
hostname = "ssh-ed25519 AAAAC3... root@hostname";

# 3. Add to allSystems list
allSystems = [ navi bee halo hostname ];

# 4. Re-encrypt all secrets
agenix --rekey

# 5. Commit changes
git add secrets.nix secrets/
git commit -m "Add hostname to secrets"
```

## Troubleshooting

### Secret not decrypting

- Ensure your SSH key is in `secrets.nix` under `allUsers`
- Check you're in `nix develop` shell for agenix command
- Verify file permissions in service config

### Permission denied

- Set correct owner/group in age.secrets config
- Check systemd service user matches secret owner

### Can't edit secrets

- Make sure you're in `nix develop` shell
- Your SSH key must be listed in `secrets.nix` `allUsers`

## Related Documentation

- [Architecture Overview](../architecture.md) - System security design
- [Security Model](../architecture/security.md) - Security practices
- [Deployment Guide](../deployment.md) - Post-deployment secret setup
