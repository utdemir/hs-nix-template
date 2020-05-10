let
  sources = import (./. + "/{{cookiecutter.project_name}}/nix/sources.nix");
  pkgs = import sources.nixpkgs {};
in
rec {

  generated = pkgs.runCommand "hs-nix-template" {
    buildInputs = [ pkgs.cookiecutter ];
    preferLocalBuild = true;
  } ''
    HOME="$(mktemp -d)"
    mkdir "$out"
    cookiecutter --no-input --output-dir "$out" ${./.}
  '';

  build = pkgs.recurseIntoAttrs
    (import "${generated}/your-project-name" {});
}
