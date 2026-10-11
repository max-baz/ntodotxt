{
  description = "Flutter development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Define the architecture
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      androidSdk = (pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "34" "35" "36" ];
        buildToolsVersions = [ "35.0.0" "36.0.0" ];
        cmakeVersions = [ "3.22.1" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
      }).androidsdk;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          bashInteractive
          cmake
          flutter341
          gtk3
          jdk21
          libsecret
          nil
          ninja
          nixd
          pre-commit
          shellcheck
          shfmt
          sqlite
        ];

        ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.sqlite
          pkgs.libsecret
        ];
      };

    };
}
