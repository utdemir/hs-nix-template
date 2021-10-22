{
  use_hpack ? "no",
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
    cookiecutter \
      --no-input --output-dir "$out" ${./.} \
      use_hpack="${use_hpack}" \
      add_executable_section="${add_executable_section}"
  '';

  build = pkgs.recurseIntoAttrs
    (import "${generated}/your-project-name" {});
}
