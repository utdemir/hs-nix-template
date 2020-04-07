{ compiler ? "ghc883" }:

let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

  gitignore = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];

  myHaskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = hself: hsuper: {
      "{{cookiecutter.project_name}}" =
        hself.callCabal2nix
          "{{cookiecutter.project_name}}"
          (gitignore ./.)
          {};
    };
  };

  shell = myHaskellPackages.shellFor {
    packages = p: [
      p."{{cookiecutter.project_name}}"
    ];
    buildInputs = with pkgs.haskellPackages; [
      myHaskellPackages.cabal-install
      ghcid
      ormolu
      hlint
      (import sources.niv {}).niv
      pkgs.nixpkgs-fmt
    ];
    withHoogle = true;
  };

  exe = pkgs.haskell.lib.justStaticExecutables (myHaskellPackages."{{cookiecutter.project_name}}");

  docker = pkgs.dockerTools.buildImage {
    name = "{{cookiecutter.project_name}}";
    config.Cmd = [ "${exe}/bin/{{cookiecutter.project_name}}" ];
  };
in
{
  inherit shell;
  inherit exe;
  inherit docker;
  inherit myHaskellPackages;
  "{{cookiecutter.project_name}}" = myHaskellPackages."{{cookiecutter.project_name}}";
}
