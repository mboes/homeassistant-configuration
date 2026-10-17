{
  inputs.nixpkgs.url = "nixpkgs";
  inputs.flake-utils.url = "flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let pkgs = import nixpkgs { inherit system; }; in
        let python3 = pkgs.python3.withPackages (ps: [ps.pyyaml]); in
        pkgs.mkShell {
          packages = [ python3 pkgs.nickel pkgs.yamlfmt pkgs.yq ];
      };
    });
}
