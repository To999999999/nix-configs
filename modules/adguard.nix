{ ... }:

{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;

    host = "10.7.0.1";
    port = 80;

    settings = {
      users = [ ];

      dns = {
        bind_hosts = [
          "10.7.0.1"
          "fd42:42:42::1"
        ];
        port = 53;

        upstream_dns = [
          "https://dns10.quad9.net/dns-query"
        ];

        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];

        enable_dnssec = true;
      };

      clients.persistent = [
	{ name = "Pi"; ids = [ "10.7.0.1" "fd42:42:42::1" ]; use_global_settings = true; }
	{ name = "MacNew"; ids = [ "10.7.0.2" "fd42:42:42::2" ]; use_global_settings = true; }
	{ name = "MacOld"; ids = [ "10.7.0.3" "fd42:42:42::3" ]; use_global_settings = true; }
	{ name = "iPhone"; ids = [ "10.7.0.4" "fd42:42:42::4" ]; use_global_settings = true; }
	{ name = "iPad"; ids = [ "10.7.0.5" "fd42:42:42::5" ]; use_global_settings = true; }
      ];

      filtering = {
	protection_enabled = true;
	filtering_enabled = true;
	rewrites_enabled = true;

	rewrites = [
	  { domain = "adguard.wg"; answer = "10.7.0.1"; enabled = true; }
	];

      };

      filters = [
        {
          enabled = true;
          name = "OISD Big";
          url = "https://big.oisd.nl/";
        }
      ];

      querylog = {
        enabled = true;
        interval = "2160h";
      };

      statistics = {
        enabled = true;
        interval = "2160h";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
