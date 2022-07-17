{
  inputs = {
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , gitignore
    , android-nixpkgs
    }:
    let
      system = "x86_64-linux";
      inherit (gitignore.lib) gitignoreSource;
      pkgs = nixpkgs.legacyPackages.${system};
      selfpkgs = self.packages.${system};
    in
    pkgs.lib.recursiveUpdate
      {
        packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
          name = "CarEdu";
          src = gitignoreSource ./.;
          buildInputs = [
            selfpkgs.godot-wrapped
          ];
          installPhase = ''
            export HOME=$(pwd)
            mkdir -p $out/bin
            godot-headless -v --export "Linux/X11" $out/bin/CarEdu
          '';
          dontStrip = true; # to make "Embed Pck" work
        };

        packages.x86_64-windows.default = pkgs.stdenv.mkDerivation {
          name = "CarEdu";
          src = gitignoreSource ./.;
          buildInputs = [
            selfpkgs.godot-wrapped
          ];
          installPhase = ''
            export HOME=$(pwd)
            mkdir -p $out/bin
            godot-headless -v --export "Windows Desktop" $out/bin/CarEdu.exe
          '';
          dontStrip = true; # to make "Embed Pck" work
        };

        packages.android.default = pkgs.stdenv.mkDerivation {
          name = "CarEdu";
          src = gitignoreSource ./.;
          buildInputs = [
            selfpkgs.godot-wrapped
            pkgs.openjdk11
          ];
          installPhase = ''
            export HOME=$(pwd)
            mkdir -p $out/bin
            godot-headless -v --export-debug "Android" $out/bin/CarEdu.apk
          '';
        };
      }
      {
        packages.${system} = {
          godot-wrapped = pkgs.runCommand "godot-wrapped"
            { nativeBuildInputs = [ pkgs.makeWrapper ]; }
            ''
              mkdir -p $out/bin
              ln -s ${selfpkgs.godot-patched}/bin/godot-headless $out/bin/godot-headless
              wrapProgram $out/bin/godot-headless \
                --set ANDROID_SDK ${selfpkgs.android-sdk}/share/android-sdk \
                --set EXPORT_TEMPLATES ${selfpkgs.export-templates} \
                --set DEBUG_KEY ${./debug.keystore}
            '';

          godot-patched = pkgs.godot-headless.overrideAttrs (oldAttrs: rec {
            preBuild = ''
              substituteInPlace platform/android/export/export_plugin.cpp \
                --replace 'String sdk_path = EditorSettings::get_singleton()->get("export/android/android_sdk_path")' 'String sdk_path = std::getenv("ANDROID_SDK")'
              substituteInPlace platform/android/export/export_plugin.cpp \
                --replace 'EditorSettings::get_singleton()->get("export/android/debug_keystore")' 'std::getenv("DEBUG_KEY")'
              substituteInPlace editor/editor_settings.cpp \
                --replace 'get_data_dir().plus_file("templates")' 'std::getenv("EXPORT_TEMPLATES")'
            '';
          });

          export-templates =
            # patch the export templates, since patching the final binary would
            # break godot's Pck embedding
            let
              godot-version = pkgs.godot-headless.version;
              unpatched = pkgs.fetchzip {
                url = "https://downloads.tuxfamily.org/godotengine/${godot-version}/Godot_v${godot-version}-stable_export_templates.tpz";
                extension = "zip";
                hash = "sha256-NG6TmfWiEBirvdrCs6mlb27mIp6sjdzvSyw4jyYvkCA=";
              };
            in
            pkgs.stdenv.mkDerivation {
              pname = "godot-export-templates";
              version = godot-version;
              buildInputs = with pkgs; [
                autoPatchelfHook
                xorg.libXcursor
                xorg.libXinerama
                xorg.libXext
                xorg.libXrandr
                xorg.libXi
                libglvnd
              ];
              dontUnpack = true;
              installPhase = ''
                mkdir -p $out
                cp -r ${unpatched} $out/${godot-version}.stable
              '';
            };

          android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
            platform-tools
            build-tools-30-0-3
            platforms-android-29
            cmdline-tools-latest
            ndk-21-4-7075529
          ]);
        };
      }
  ;
}
