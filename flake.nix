{
  description = "Raspberry_pi_4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    fan-controller.url = "path:./fan-controller";
  };

  outputs = { self, nixpkgs, sops-nix, fan-controller, ... }:
  {
    nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
	fan-controller.nixosModules.default
  	{
    	  nixpkgs.overlays = [
      	    (final: prev: {
	      fan = fan-controller.packages.${prev.system}.default;
      	    })
    	  ];
  	}
      ];
    };
  };
}
