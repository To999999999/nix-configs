{ ... }:

{
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs 10.7.0.0/24(ro,fsid=0,crossmnt,insecure,no_subtree_check)
      /srv/nfs fd42:42:42::/64(ro,fsid=0,crossmnt,insecure,no_subtree_check)

      /srv/nfs/Backup 10.7.0.0/24(rw,all_squash,insecure,async,no_subtree_check,anonuid=1000,anongid=1000)
      /srv/nfs/Backup fd42:42:42::/64(rw,all_squash,insecure,async,no_subtree_check,anonuid=1000,anongid=1000)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
