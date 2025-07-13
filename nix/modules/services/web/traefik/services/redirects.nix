# Redirect services configuration for Traefik
#
# This module defines URL redirects without backend services.
# All redirects are public and use the main domain (jeremyk.net).
#
# Current redirects:
# - meet.jeremyk.net -> Google Meet room
#
# To add a new redirect:
# 1. Add an entry to redirectDefinitions with from, to, and permanent fields
# 2. The service and middleware will be automatically generated
#
{lib, ...}: let
  # Import helper functions
  helpers = import ../lib.nix {inherit lib;};
  
  # Define all redirects in one place
  redirectDefinitions = {
    meet = {
      from = "meet";
      to = "https://meet.google.com/geq-fmkx-bde";
      permanent = false;
    };
    # Add more redirects here as needed
  };
  
  # Generate everything from redirect definitions
  generated = helpers.mkRedirects redirectDefinitions;
in 
  generated // { tailscale = {}; }