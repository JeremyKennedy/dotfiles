# Secrets Management with Agenix

This repository uses [agenix](https://github.com/ryantm/agenix) to manage encrypted secrets that are safe to commit to git.

## Workflow with secrets.json

This repository uses a two-tier approach for secret management:

- **`secrets.json`**: Local plain-text reference file (gitignored, never committed)
- **`secrets/*.age`**: Encrypted files generated from secrets.json (safe to commit)

The `secrets.json` file serves as your local "source of truth" that feeds into agenix encryption. This gives you:
- ✅ Easy editing in plain text  
- ✅ Individual encrypted secrets (one per value)
- ✅ Simple management workflow
- ✅ No risk of accidentally committing secrets

## Current Secrets

- **Home Assistant**: Token and server URL for hass-cli
- **ChatGPT**: API key for chatgpt-cli
- **Grist**: API key and proxy auth for payment updater service

## Managing Secrets

### Viewing Current Secrets

To see what secrets are available:
```bash
ls secrets/
# Shows: chatgpt_key.age  grist_api_key.age  grist_proxy_auth.age  hass_server.age  hass_token.age
```

### Editing Secrets

To update any secret:

1. **Edit the `secrets.json` file**:
```bash
vim secrets.json
```

2. **Re-encrypt the updated secrets**:
```bash
# Re-encrypt individual secrets from secrets.json
jq -r .hass_token secrets.json | agenix -e secrets/hass_token.age
jq -r .hass_server secrets.json | agenix -e secrets/hass_server.age
jq -r .chatgpt_key secrets.json | agenix -e secrets/chatgpt_key.age
jq -r .grist_api_key secrets.json | agenix -e secrets/grist_api_key.age
jq -r .grist_proxy_auth secrets.json | agenix -e secrets/grist_proxy_auth.age
```

### Adding New Secrets

1. Add the secret definition to `secrets.nix`:
```nix
{
  "secrets/newsecret.age".publicKeys = allUsers ++ allSystems;
}
```

2. Add to NixOS secrets config in `nixos/secrets.nix`:
```nix
newsecret = {
  file = ../secrets/newsecret.age;
  owner = "jeremy";  # or appropriate user
};
```

3. Add the new secret to `secrets.json` and encrypt it:
```bash
# Add to secrets.json, then:
jq -r .newsecret secrets.json | agenix -e secrets/newsecret.age
```


### Applying Changes

After updating secrets:

1. **Rebuild the system** to update system services:
```bash
sudo nixos-rebuild switch
```

2. **Restart your shell** or run to reload environment variables:
```bash
exec $SHELL
```

For systemd services, you may need to restart them:
```bash
sudo systemctl restart grist-payment-updater.service
```

### Troubleshooting

**"Permission denied" when editing secrets:**
- Make sure you have the SSH key that was used to encrypt the secrets
- Your SSH key should be listed in `secrets.nix`

**Environment variables not updated:**
- Restart your shell: `exec $SHELL`
- For Fish shell: `exec fish`

**Secrets not working after rebuild:**
- Check if the secret file exists: `ls -la /run/agenix/`
- Check systemd service logs: `journalctl -u service-name`

### Security Notes

- Encrypted `.age` files are safe to commit to git
- Never commit the plain `secrets.json` file (it's gitignored)
- Secrets are decrypted at runtime to `/run/agenix/`
- Only specified users/groups can read decrypted secrets

### Re-keying (Adding New SSH Keys)

If you need to add a new machine or user:

1. Add their SSH public key to `secrets.nix`
2. Re-encrypt all secrets:
```bash
agenix -r
```