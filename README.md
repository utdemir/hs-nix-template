# hs-nix-template

A [cookiecutter] template which creates a Haskell project that

* Can be built with Nix and cabal-install,
* Has a library, an executable and a test suite,
* Comes with a `shell.nix` which provides an environment with `ghcid`,
* Uses a pinned `nixpkgs`.

## Usage

No need to install anything, just run:

```
nix-shell -p cookiecutter git --run 'cookiecutter gh:utdemir/hs-nix-template'
```

[cookiecutter]: https://cookiecutter.readthedocs.io/en/latest/readme.html
