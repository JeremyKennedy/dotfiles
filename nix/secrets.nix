let
  jeremy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7YCbzW2kMJxx2YIN2XLGpLZMNzcTjB6WWmvKPVjVnR me@jeremyk.net";
  jeremyDesktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkcW6NRwi4Y28F8Zo9rDfwxc+qEt9kxKvLd++q5L2iu root@JeremyDesktop";
  
  allUsers = [ jeremy ];
  allSystems = [ jeremyDesktop ];
in
{
  "secrets/hass_token.age".publicKeys = allUsers ++ allSystems;
  "secrets/hass_server.age".publicKeys = allUsers ++ allSystems;
  "secrets/chatgpt_key.age".publicKeys = allUsers ++ allSystems;
  "secrets/grist_api_key.age".publicKeys = allUsers ++ allSystems;
  "secrets/grist_proxy_auth.age".publicKeys = allUsers ++ allSystems;
}