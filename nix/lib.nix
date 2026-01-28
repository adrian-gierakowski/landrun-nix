{ pkgs, lib ? pkgs.lib, ... }:

rec {
  evalModules = { name ? "landrun", modules }: (lib.evalModules {
    specialArgs = {
      inherit name pkgs;
    };
    modules = [
      ../modules/flake-parts/landrun/options.nix
      ../modules/flake-parts/landrun/features.nix
      ../modules/flake-parts/landrun/wrapper.nix
    ] ++ modules;
  });

  makeLandrun = { name, modules }: (evalModules {
    inherit name modules;
  }).config.wrappedPackage;
}
