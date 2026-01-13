{ pkgs }: {
  deps = [
    # Node.js for React frontend
    pkgs.nodejs_20
    pkgs.nodePackages.npm

    # Java for NPL CLI (some operations may need it)
    pkgs.jdk17

    # Utilities
    pkgs.curl
    pkgs.jq
    pkgs.bash
    pkgs.gnumake
  ];

  env = {
    # Add NPL CLI to PATH after installation
    PATH = "/home/runner/.npl/bin:$PATH";
  };
}
