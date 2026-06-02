{
  pkgs,
  lib,
  ...
}:

pkgs.mkShell {
  packages =
    with pkgs;
    [
      # Development packages
      #gitMinimal
      #umoci
    ]
    ++ lib.optionals (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.felix86) [
      pkgs.felix86
    ];
}
