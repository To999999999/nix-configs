{ ... }:

{
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/9c92f673-a34a-45c6-bc8f-1c4d88c254be";
    fsType = "ext4";
  };

  fileSystems."/srv/nfs/Backup" = {
    device = "/mnt/data/Backup";
    fsType = "none";
    options = [ "bind" ];
    depends = [ "/mnt/data" ];
  };
}
