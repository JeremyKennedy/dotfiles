# Action Items

## Future Enhancements

### Backup Strategy

- Implement automated backups for stateful data
- Consider backup solutions for:
  - AdGuard Home configuration
  - Traefik certificates
  - Service configurations
  - Database backups from Unraid services

### GitOps Pipeline

- Automated deployment on git push
- CI/CD with Woodpecker CI or GitHub Actions
- Automated testing and rollback capabilities
- Consider:
  - Pre-commit hooks for `nix flake check`
  - Automatic deployment to staging first
  - Health checks before promoting to production

### Documentation

- Create service architecture diagram
- Document emergency recovery procedures
- Write runbooks for common maintenance tasks
