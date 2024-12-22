{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.cudaSupport = true;
    };
  in {
    packages."${system}" = {
      runstats = pkgs.python3Packages.buildPythonPackage {
        pname = "runstats";
        version = "v2.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "grantjenks";
          repo = "python-runstats";
          tag = "v2.0.0";
          sha256 = "sha256-YF6S5w/ccWM08nl9inWGbaLKJ8/ivW6c7A9Ny20fldU=";
        };
      };

      fastmri = pkgs.python3Packages.buildPythonPackage rec {
        pname = "fastmri";
        version = "v0.3.0";

        src = pkgs.fetchFromGitHub {
          owner = "facebookresearch";
          repo = "fastmri";
          rev = "v0.3.0";
          sha256 = "sha256-0IJV8OhY5kPWQwUYPKfmdI67TyYzDAPlwohdc0jWcV4=";
        };

        # do not run tests
        doCheck = false;
        # specific to buildPythonPackage, see its reference
        pyproject = true;
        build-system = with pkgs.python3Packages; [
          setuptools
          setuptools-scm # wtf is this
        ];
        propagatedBuildInputs = with pkgs.python3Packages; [
          torchWithCuda
          torchvision
          pytorch-lightning
          scikit-image
          h5py
          torchmetrics
          pandas
          self.outputs.packages."${system}".runstats
        ];

        pythonImportsCheck = ["fastmri"];
      };
      default = self.packages."${system}".fastmri;
    };
  };
}
