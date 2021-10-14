{ compiler ? "ghc8104" }:

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
    buildInputs = [
      myHaskellPackages.haskell-language-server
      pkgs.haskellPackages.cabal-install
      pkgs.haskellPackages.ghcid
      pkgs.haskellPackages.ormolu
      pkgs.haskellPackages.hlint
      {% if cookiecutter.project_configuration_tool.startswith("package.yaml") %}pkgs.haskellPackages.hpack
      {% endif -%}
      pkgs.niv
      pkgs.nixpkgs-fmt
    ];
    withHoogle = true;
  };
{% if cookiecutter.add_executable_section == "yes" %}
  exe = pkgs.haskell.lib.justStaticExecutables (myHaskellPackages."{{cookiecutter.project_name}}");

  docker = pkgs.dockerTools.buildImage {
    name = "{{cookiecutter.project_name}}";
    config.Cmd = [ "${exe}/bin/{{cookiecutter.project_name}}" ];
  };
{% endif -%}
in
{
  inherit shell;
  {% if cookiecutter.add_executable_section == "yes" %}inherit exe;
  inherit docker;
  {% endif -%}
  inherit myHaskellPackages;
  "{{cookiecutter.project_name}}" = myHaskellPackages."{{cookiecutter.project_name}}";
}
