{
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , gitignore
    }:
    let
      inherit (gitignore.lib) gitignoreSource;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      godot-version = pkgs.godot-headless.version;
      export-templates =
        # patch the export templates, since patching the final binary would
        # break godot's Pck embedding
        let
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
            cp -r ${unpatched} $out
          '';
        };
    in
    {
      packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
        name = "CarEdu";
        src = gitignoreSource ./.;
        buildInputs = with pkgs; [
          godot-headless
        ];
        installPhase = ''
          export HOME=$(pwd)
          mkdir -p ~/.local/share/godot/templates/
          ln -s ${export-templates} ~/.local/share/godot/templates/${godot-version}.stable
          mkdir -p $out/bin
          godot-headless -v --export "Linux/X11" $out/bin/CarEdu
        '';
        dontStrip = true; # to make "Embed Pck" work
      };

      packages.x86_64-windows.default = pkgs.stdenv.mkDerivation {
        name = "CarEdu";
        src = gitignoreSource ./.;
        buildInputs = with pkgs; [
          godot-headless
        ];
        installPhase = ''
          export HOME=$(pwd)
          mkdir -p ~/.local/share/godot/templates/
          ln -s ${export-templates} ~/.local/share/godot/templates/${godot-version}.stable
          mkdir -p $out/bin
          godot-headless -v --export "Windows Desktop" $out/bin/CarEdu.exe
        '';
        dontStrip = true; # to make "Embed Pck" work
      };
    };
}
