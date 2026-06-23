{ ... }:

{
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs 10.7.0.0/24(rw,fsid=0,crossmnt,insecure,no_subtree_check,all_squash,anonuid=1001,anongid=100)
      /srv/nfs fd42:42:42::/64(rw,fsid=0,crossmnt,insecure,no_subtree_check,all_squash,anonuid=1001,anongid=100)

      /srv/nfs/Backup 10.7.0.0/24(rw,async,all_squash,insecure,no_subtree_check,anonuid=1001,anongid=100)
      /srv/nfs/Backup fd42:42:42::/64(rw,async,all_squash,insecure,no_subtree_check,anonuid=1001,anongid=100)
    '';
  };

  services.nfs.settings = {
    nfsd = {
      vers3 = false;
      vers4 = true;
      "vers4.0" = true;
      "vers4.1" = true;
      "vers4.2" = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
