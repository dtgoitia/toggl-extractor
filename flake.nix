{
  description = "Tool to regularly extract data from Toggl";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    name = "toggl-extractor";

    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.buildDartApplication rec {
          pname = name;
          version = "0.0.1";
          src = pkgs.lib.cleanSource ./.;
          autoPubspecLock = ./pubspec.lock;
          dartEntryPoints = {
            "bin/${name}" = "bin/main.dart";
          };
        };
      }
    );

    apps = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        dart_run = {
          type = "app";
          program = pkgs.lib.getExe (pkgs.writeShellScriptBin "dart-run" "${pkgs.dart}/bin/dart run");
        };

        compile = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellScriptBin
            "dart-compile"
            ''
              entry_point='bin/main.dart'
              output='dist/toggl-extractor'
              mkdir -p dist
              ${pkgs.dart}/bin/dart compile exe --output "$output" "$entry_point"
            ''
          );
        };
      }
    );

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.dart
        ];
        shellHook = ''
          echo "Disabling dart telemetry"
          dart --disable-analytics

          exec fish
        '';
      };
    });
  };
}
