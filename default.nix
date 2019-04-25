{ compiler ? "ghc864"
, pkgs ? import ./pkgs.nix
}:

let
gitignore = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];

overlays = se: su: {
  "example" =
    se.callCabal2nix 
      "example" 
      (gitignore ./.) 
      {};
      
  # Always use the new Cabal
  Cabal = se.Cabal_2_4_1_0;
  
  # Pulls in a broken dependency on 1.8.1, fixed in master but no new release yet.
  # https://github.com/yesodweb/Shelly.hs/commit/8288d27b93b57574135014d0888cf33f325f7c80
  shelly =
    se.callCabal2nix 
      "shelly"
      (builtins.fetchGit {
        url = "https://github.com/yesodweb/Shelly.hs";
        rev = "8288d27b93b57574135014d0888cf33f325f7c80";
      })
      {};

  # Upstream does not compile with Cabal 2.4 yet.
  # See: https://github.com/ktvoelker/standalone-haddock/issues/18  
  standalone-haddock = 
    se.callCabal2nix
      "standalone-haddock"
      (builtins.fetchGit {
        url = "https://github.com/utdemir/standalone-haddock";
        rev = "134c0560156a49cbdc3d656543d1a44092765500";
      })
      {};
};

haskellPackages = pkgs.haskell.packages.${compiler}.override {
  overrides = overlays;
};

in rec
{ 
  "example" = haskellPackages.example;
  shell = haskellPackages.shellFor {
    packages = p: with p; [ 
      example
    ];
    buildInputs = with haskellPackages; [ 
      cabal-install 
      ghcid 
      stylish-haskell 
      hlint
    ]; 
    withHoogle = true;
  };
  
  docs = pkgs.runCommand "example-docs" {
    buildInputs = with haskellPackages;
      [ (haskellPackages.ghcWithPackages (hp: 
          [ example ]))
        standalone-haddock
      ];
  } ''
    mkdir "$out"
    standalone-haddock \
      --dist-dir "$(mktemp -d)" \
      -o "$out" \
      ${example.src} 
  '';
}

