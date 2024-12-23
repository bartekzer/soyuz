/*
SPDX-FileCopyrightText: 2024 Łukasz Bartkiewicz <lukasku@proton.me>

SPDX-License-Identifier: MPL-2.0
*/
{
  description = "The Soyuz Communication Protocol";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    fenix,
    naersk,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      toolchain = with fenix.packages.${system};
        combine [
          complete.toolchain
        ];

      naersk-lib = naersk.lib.${system}.override {
        inherit (toolchain);
        rustc = toolchain;
        cargo = toolchain;
      };

      formatter = pkgs.alejandra;

      soyuz = naersk-lib.buildPackage {
        name = "soyuz";
        src = ./.;
      };
    in {
      inherit formatter;
      packages.soyuz = soyuz;
      defaultPackage = self.packages.${system}.soyuz;

      devShell = pkgs.mkShell rec {
        packages = with pkgs; [toolchain rustup reuse pre-commit];
        RUST_BACKTRACE = 0;
        RUSTFLAGS = "-Zmacro-backtrace";
      };
    });
}
