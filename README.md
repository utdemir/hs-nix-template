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

Once that completes, `cd` into the directory and call:

```
nix-shell
```

(includes: `ghc865`, `cabal`, `hoogle`, `ghcid`, `ormolu`, `hlint`, `niv` and `nixpkgs-fmt`)

Or you can directly build the executable for your project with:

```
nix-build --attr exe
```

Or deploy to docker image:

```
nix-build --attr docker
```

And load the resulting image:

```
docker load -i result
```

[cookiecutter]: https://cookiecutter.readthedocs.io/en/latest/readme.html

## Cheat Sheet

### Run Hoogle locally

- `hoogle server --local -p 3000 -n`

You need the `-n` to stop hoogle from trying to use https locally. You will need to kill and reload this whenever you add or remove a dependency in your cabal file (if you use [lorri] your shell will reload for you as well). This is so `hoogle` will use the newly generated database with your added/modified dependencies.

### Add external source with [niv]

- From Hackage
  - `niv add extra --version 1.6.20 -a name=extra -t 'https://hackage.haskell.org/package/<name>-<version>/<name>-<version>.tar.gz'`
- From GitHub with specific revision
  - `niv add ndmitchell/ghcid -a rev=e3a65cd986805948687d9450717efe00ff01e3b5`

[niv]: https://github.com/nmattia/niv 

### Add external tool to `default.nix`

The sources you pull down with `niv` are accessible under `sources.<name>`. Its a derivation with the attributes you need to fetch the source, not the source itself. If you want to pull in a source you need to either give it to a function that knows how to fetch the contents like `callCabal2nix` or if the source has a `default.nix` you can import it directly, like so: `import sources.niv {}`.

---

Often you will want to explore what you have just imported since you may only want one of its attributes, you can do this by adding the source as an exported attribute in your `default.nix`:

```
in
  if pkgs.lib.inNixShell then shell else {
    inherit exe;
    inherit docker;
    ### Added here
    src = import sources.niv {};
  }

```

Then call `nix repl default.nix` and you can tab complete `src.<tab>` to see what attributes are inside. (Note, this is how I know to call `(import sources.niv {}).niv` to get the `niv` derivation).

---

On the other hand here is an example with `callCabal2nix` adding the specific version of `ghcid` we fetched earlier to our development shell:

```
    buildInputs = with pkgs.haskellPackages; [
      cabal-install
      ### Added modified development tool here
      (pkgs.haskell.lib.justStaticExecutables
          (callCabal2nix "ghcid" (sources.ghcid) {}))
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

  shell = myHaskellPackages.shellFor {
    packages = p: [
```

Then add it to the end of your `callCabal2nix` call:

```
      (pkgs.haskell.lib.justStaticExecutables
          (callCabal2nix "ghcid" (sources.ghcid) {inherit extra;}))
```

Note: I am building `ghcid` with `haskellPackages` not `myHaskellPackages`. If the tool fails to build you might want to either use a different package set or modify one yourself so the tool has the right dependencies.

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

### Add external dependency to `default.nix`

Lets say you wanted to add `extra` as dependency of your project and its not in the package set by default:

```
  myHaskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = hself: hsuper: {
      ### Add new dependences here
      extra =
        hself.callCabal2nix
          "extra"
          (sources.extra)
          {};
      "your project name" =
        hself.callCabal2nix
          "your project name"
          (gitignore ./.)
          {};
    };
  };
```

This will not only add `extra` to your project, but also build the documentation for you. However, to get it in your local hoogle database you need to add it to your cabal file and then call `nix-shell`.

### Override dependency in `default.nix`

If you want to override a dependency you add it like we did above with `extra`, just make sure the name is identical to what is in the package set. As you would expect, the name in the package set is the same as the name on Hackage. There are a few packages with multiple versions, like `zip` and `zip_1_4_1`.

If you want to see exactly what is in your modified package set add this to your `default.nix` :

```
in
  if pkgs.lib.inNixShell then shell else {
  inherit exe;
  inherit docker;
  ### Added here
  inherit myHaskellPackages;
}
```

Then call `nix repl default.nix` and you will get this:

```

Loading 'default.nix'...
Added 3 variables.

nix-repl>
```

Then you can tab complete to see what is in `myHaskellPackages`

```
nix-repl> myHaskellPackages.ex<tab>
```

Note: the reason we don't have this attribute added by default is you really only need this for debugging and wouldn't want your continuous integration to build the package set as an output of your project.

### Deploy to Docker Image

The third project in [haskell-nix] goes into detail how this works, but we have already included docker under the `docker` attribute. 

Note: if your project name has a space in it, the executable path will be wrong.

[haskell-nix]: https://github.com/Gabriel439/haskell-nix/tree/master/project3#minimizing-the-closure
