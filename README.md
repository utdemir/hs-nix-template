# hs-nix-template

[![CI Status](https://github.com/utdemir/hs-nix-template/workflows/ci/badge.svg)](https://github.com/utdemir/hs-nix-template/actions)

A [cookiecutter] template which creates a Haskell project that

* Can be built with Nix and cabal-install,
* Has a library, an executable and a test suite,
* Comes with a `shell.nix` which provides an environment with `ghcid`,
* `ghci` integrates with Haddock and Hoogle for all dependencies (`:doc`, `:hoogle`),
* Uses a pinned `nixpkgs`.

## Usage

No need to install anything, just run:

```
nix-shell -p cookiecutter git --run 'cookiecutter gh:utdemir/hs-nix-template'
```

[cookiecutter]: https://cookiecutter.readthedocs.io/en/latest/readme.html

## Cheat Sheet

### Run Hoogle locally

- `hoogle server --local -p 3000 -n`

You need the `-n` to stop hoogle from trying to use https locally. You will need to kill and reload this whenever you add or remove a dependency in your cabal file.

### Add external source with [niv]

- From Hackage
  - `niv add extra --version 1.6.20 -a name=extra -t 'https://hackage.haskell.org/package/<name>-<version>/<name>-<version>.tar.gz'`
- From GitHub with specific revision
  - `niv add ndmitchell/ghcid -a rev=e3a65cd986805948687d9450717efe00ff01e3b5`

[niv]: https://github.com/nmattia/niv 

### Add external tool to `default.nix`

The sources you pull down with `niv` are accessible under `sources.<name>`. Here is an example adding the specific version of `ghcid` we fetched earlier to our development shell:

```
    buildInputs = with pkgs.haskellPackages; [
      cabal-install
      ### Added modified development tool here
      (pkgs.haskell.lib.justStaticExecutables
          (pkgs.haskellPackages.callCabal2nix "ghcid" (sources.ghcid) {}))
      ###
      ormolu
      hlint
      pkgs.niv
      pkgs.nixpkgs-fmt
    ];
```

If you exit your `nix-shell` to reload this change you will find it won't build. However, this means you won't have access to `niv` or other development tools you may need to get the derivation building again. I strongly recommend using [lorri] to handle re-building your development environment, among other useful features it will load up the last successful build for your development environment alleviating this issue entirely.

To get this version of `ghcid` building you need to provide a specific version of the `extra` library:

```
  extra = pkgs.haskellPackages.callCabal2nix "extra" (sources.extra) {};
in
rec
```

Then add it to the end of your `callCabal2nix` call:

```
      (pkgs.haskell.lib.justStaticExecutables
          (pkgs.haskellPackages.callCabal2nix "ghcid" (sources.ghcid) {inherit extra;}))
```

[lorri]: https://github.com/target/lorri

#### Speed up dependency building

For some packages, like `extra` we don't need its documentation or setup for profiling since its just a dependency of a build tool. You can speed up building dependencies with a modified package set:

```
  fastHaskellPackages = pkgs.haskellPackages.override {
    overrides = hself: hsuper: rec {
      mkDerivation = args: hsuper.mkDerivation (args // {
        doCheck = false;
        doHaddock = false;
        enableLibraryProfiling = false;
        enableExecutableProfiling = false;
        jailbreak = true;
      });
    };
  };

  ### The external library then is build with the modified package set
  extra = fastHaskellPackages.callCabal2nix "extra" (sources.extra) {};
```

### Add external dependency to project

Lets say you wanted to make `extra` a dependency of your project:

```
  myHaskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = se: su: {
      ### Add new dependences here
      extra =
        se.callCabal2nix
          "extra"
          (sources.extra)
          {};
      "test" =
        se.callCabal2nix
          "test"
          (gitignore ./.)
          {};
    };
  };
```

This will not only add `extra` to your project, but also build the documentation for you and add it to your local hoogle database. 

### Override dependency to project

If you want to override a dependency you add it like we did above with `extra`, but make sure the name is the same as what it is in the package set. A quick way to see what is in your modified Haskell package set is to export it and open it up with `nix repl`.

Add this to your `default.nix`

```
    ];
    withHoogle = true;
  };
  ### Added here
  pkgs = myHaskellPackages;
}
```

call `nix repl default.nix` and you will get this:

```

Loading 'default.nix'...
Added 3 variables.

nix-repl>
```

Then you can tab complete to see what is in `pkgs`

```
nix-repl> pkgs.ex<tab>
```
