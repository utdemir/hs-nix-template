{ compiler ? "ghc865" }:

let
sources = import ./nix/sources.nix;
pkgs = import sources.nixpkgs {};

gitignore = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];

haskellPackages = pkgs.haskell.packages.${compiler}.override {
  overrides = se: su: {
    "{{cookiecutter.project_name}}" =
      se.callCabal2nix
        "{{cookiecutter.project_name}}"
        (gitignore ./.)
        {};
  };
};

in rec
{
  "{{cookiecutter.project_name}}" = haskellPackages.{{cookiecutter.project_name}};
  shell = haskellPackages.shellFor {
    packages = p: with p; [
      {{cookiecutter.project_name}}
    ];
    buildInputs = with haskellPackages; [
      cabal-install
      ghcid
      ormolu
      hlint
      pkgs.niv
    ];
    withHoogle = true;
  };
}

