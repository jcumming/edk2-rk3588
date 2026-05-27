{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule

      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          # packages.default = pkgs.hello;

          devShells.default = pkgs.mkShell {
            # GCC 15 defaults to C23 (breaks `typedef BOOLEAN bool;`) and adds
            # -Wunterminated-string-initialization (SCMI domain name length).
            # Pin to GCC 14 which matches what Debian/Ubuntu ship for this
            # project and avoids these regressions.
            packages = with pkgs; [
              gcc14
            ];
            nativeBuildInputs = with pkgs; [
              gnumake
              python3
              python3Packages.pyelftools # for FIT image generation (extractbl31.py)
              util-linux # for uuid/uuid.h
              openssl # EDK2 Crypto build
              nasm # assembly in some EDK2 libs
              acpica-tools # for iasl
              dtc
            ];
            # Nix's GCC hardening wrapper injects -Wformat -Wformat-security
            # -Werror=format-security.  EDK2's OpenSSL build disables -Wformat
            # (via -Wno-format), which makes -Wformat-security a no-op that
            # GCC errors on under -Werror.  Disable the `format` hardening to
            # match the behaviour on Debian/Ubuntu where these flags are not
            # injected by the toolchain wrapper.
            hardeningDisable = [ "format" ];

            # The Nix GCC/binutils build environment sets AS=as (bare
            # assembler), but TF-A expects a GCC-compatible assembler because
            # its build rules pass -x assembler-with-cpp (a GCC flag).  Unset
            # AS so TF-A derives the assembler from the C compiler instead.
            # This is not needed on Debian/Ubuntu where AS is unset by default.
            shellHook = ''
              unset AS
            '';
          };
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
