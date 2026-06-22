{ config, lib, pkgs, ... }:

let
  wgPort = 51820;
in
{
  environment.systemPackages = [ pkgs.wireguard-tools ];

  # Server routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall.allowedUDPPorts = [ wgPort ];

  networking.nat = {
    enable = true;
    externalInterface = "end0"; # change to your Pi WAN interface
    internalInterfaces = [ "wg0" ];
    enableIPv6 = true;
  };

  sops.defaultSopsFile = ../secrets/wireguard.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Secrets, if using sops-nix
  sops.secrets.wg-server-private = {
    owner = "root";
    mode = "0400";
  };

  sops.secrets.wg-client1-psk = { owner = "root"; mode = "0400"; };
  sops.secrets.wg-client2-psk = { owner = "root"; mode = "0400"; };
  sops.secrets.wg-client3-psk = { owner = "root"; mode = "0400"; };
  sops.secrets.wg-client4-psk = { owner = "root"; mode = "0400"; };
  sops.secrets.wg-client5-psk = { owner = "root"; mode = "0400"; };

  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.7.0.1/24"
      "fd42:42:42::1/64"
    ];
    listenPort = wgPort;
    privateKeyFile = config.sops.secrets.wg-server-private.path;

    peers = [
      {
        # client1 public key: safe to commit
        publicKey = "elA8jwYRqgOp6nUwL6RoW6U9pfvBTHq7Nm+qfNUW700=";
        presharedKeyFile = config.sops.secrets.wg-client1-psk.path;
	allowedIPs = [ "10.7.0.2/32" "fd42:42:42::2/128" ];
      }
      {
        publicKey = "WNBUBFW6POJ7mfKdlGJ/ZiWPsSqVaD6kPtWZxeRj7Sg=";
        presharedKeyFile = config.sops.secrets.wg-client2-psk.path;
	allowedIPs = [ "10.7.0.3/32" "fd42:42:42::3/128" ];
      }
      {
        publicKey = "MihXzBNGYk0vy7jzMStXaQ9nM3j42Nc5aqql8pGXZTo=";
        presharedKeyFile = config.sops.secrets.wg-client3-psk.path;
	allowedIPs = [ "10.7.0.4/32" "fd42:42:42::4/128" ];
      }
      {
        publicKey = "uyu761xsvAB8kpBTrCmvxUjp8I4czb0xDNd/R5PdgW8=";
        presharedKeyFile = config.sops.secrets.wg-client4-psk.path;
	allowedIPs = [ "10.7.0.5/32" "fd42:42:42::5/128" ];
      }
      {
        publicKey = "0Cb1q52q+ow4rxu+iDaTyNlHf39kpwq4Zc8QC+s5VVo=";
        presharedKeyFile = config.sops.secrets.wg-client5-psk.path;
	allowedIPs = [ "10.7.0.6/32" "fd42:42:42::6/128" ];
      }
    ];
  };
}
