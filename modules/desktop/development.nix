# Development tools and IDEs
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # IDEs and Editors
    # jetbrains.datagrip # Temporarily disabled due to build failure
    smartgithg # git client
    vscode # code editor
    code-cursor # AI-powered code editor

    # Development Runtimes
    bun # fast all-in-one javascript runtime
    uv # fast python package installer
  ];
}
