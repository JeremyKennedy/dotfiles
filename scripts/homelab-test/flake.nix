{
  description = "Homelab Test Framework Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      python = pkgs.python3.withPackages (ps:
        with ps; [
          httpx
          rich
          python-dateutil
          tomli
        ]);
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python
          # Development tools
          just # Command runner
          ruff # Python linter/formatter
          mypy # Type checker
        ];

        shellHook = ''
          echo "🏠 Homelab Test Framework Development Environment"
          echo "Available commands:"
          echo "  just start / just run                # Full health check"
          echo "  just core                            # Core infrastructure only"
          echo "  just json                            # JSON output"
          echo "  just lint / just fix / just fmt      # Code quality"
          echo ""
          echo "Direct commands:"
          echo "  python -m homelab_test.cli --help    # CLI help"
          echo "  ruff check . / ruff format .         # Manual linting"
          echo ""

          # Set Python path to include src directory
          export PYTHONPATH="$PWD/src:$PYTHONPATH"
        '';
      };
    });
}
