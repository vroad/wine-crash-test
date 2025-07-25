{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = pkgs.callPackage ./min-vst-host.nix { };

      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = with pkgs; [ xorg.libX11 jack2 ];

        nativeBuildInputs = with pkgs; [
          gdb
          cpplint
          clang-tools
          pre-commit
          nixpkgs-fmt
          nodejs_24
          wine64
        ];
      };
    };
}
