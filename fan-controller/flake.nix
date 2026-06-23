{
  description = "Raspberry Pi PWM fan controller";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "aarch64-linux" "x86_64-linux" ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    pkgsFor = system: import nixpkgs { inherit system; };
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = pkgsFor system;
      in
      {
        default = pkgs.python3Packages.buildPythonApplication {
          pname = "fan";
          version = "0.1.0";

          pyproject = false;
          dontUnpack = true;

          propagatedBuildInputs = with pkgs.python3Packages; [
	    lgpio
            psutil
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp ${./fan.py} $out/bin/fan
            chmod +x $out/bin/fan

            substituteInPlace $out/bin/fan \
              --replace-fail '["pkill",' '["${pkgs.procps}/bin/pkill",'
          '';

          meta = {
            description = "PWM fan controller for Raspberry Pi";
            mainProgram = "fan";
          };
        };
      });

    nixosModules.default = import ./module.nix;
  };
}
