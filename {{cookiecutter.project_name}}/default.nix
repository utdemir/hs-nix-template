{ compiler ? "ghc865" }:

let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

  gitignore = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];

  myHaskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = se: su: {
      "{{cookiecutter.project_name}}" =
        se.callCabal2nix
          "{{cookiecutter.project_name}}"
          (gitignore ./.)
          {};
    };
  };

in
rec
{
  "{{cookiecutter.project_name}}" = myHaskellPackages."{{cookiecutter.project_name}}";
  shell = myHaskellPackages.shellFor {
    packages = p: [
      p."{{cookiecutter.project_name}}"
    ];
    buildInputs = with pkgs.haskellPackages; [
      cabal-install
      ghcid
      ormolu
      hlint
      pkgs.niv
      pkgs.nixpkgs-fmt
    ];
    withHoogle = true;
  };
}
