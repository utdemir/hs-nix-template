{
  project_configuration_tool ? "your-project-name.cabal (cabal's default)",
  add_executable_section ? "no"
}:

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
    cookiecutter --no-input --output-dir "$out" ${./.} project_configuration_tool="${project_configuration_tool}" add_executable_section="${add_executable_section}"
  '';

  build = pkgs.recurseIntoAttrs
    (import "${generated}/your-project-name" {});
}
