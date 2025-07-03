{
  description = "A flake for building the Raspberry Pi fork of OpenOCD";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { self, nixpkgs }:
    let
      rev = "8b8c9731a514d3e4dd367d4e77826711201b81b3";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
        }
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          openocd-raspberrypi = pkgs.stdenv.mkDerivation rec {
            pname = "openocd-raspberrypi";
            version = "git-${rev}";
            src = pkgs.fetchFromGitHub {
              owner = "raspberrypi";
              repo = "openocd";
              rev = rev;
              sha256 = "sha256-ljVb/r1tGLjaLZASU+EHkLPpyDFsDKCyrIh3II3aKCY=";
              fetchSubmodules = true;
            };
            nativeBuildInputs = with pkgs; [
              automake
              autoconf
              texinfo
              libtool
              pkg-config
              which
            ];
            buildInputs = with pkgs; [
              libftdi1
              libusb1
              hidapi
              libjaylink
              jimtcl
              tcl
              capstone
            ];
            preConfigure = ''
              ./bootstrap
            '';
            configureFlags = [
              "--disable-werror"
              "--enable-ftdi"
              "--enable-sysfsgpio"
              "--enable-bcm2835gpio"
              "--enable-picoprobe"
              "--enable-cmsis-dap"
              "--enable-hidapi"
              "--enable-capstone"
              "--enable-jlink"
              "--enable-remote-bitbang"
            ];
            postInstall = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              mkdir -p "$out/etc/udev/rules.d"
              rules="$out/share/openocd/contrib/60-openocd.rules"
              if [ ! -f "$rules" ]; then
                  echo "$rules is missing, must update the Nix file."
                  exit 1
              fi
              ln -s "$rules" "$out/etc/udev/rules.d/"
            '';
            meta = with pkgs.lib; {
              description = "OpenOCD fork for Raspberry Pi Pico";
              homepage = "https://github.com/raspberrypi/openocd";
              license = licenses.gpl2Plus;
              maintainers = [ maintainers.ifelse023 ];
              platforms = platforms.linux;
            };
          };
          default = self.packages.${system}.openocd-raspberrypi;
        }
      );
    };
}
