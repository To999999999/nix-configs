{ ... }:

{
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZ81uLlrCQ0LztEOhSINdmLomNfqnB+dCL6AVAvHfaH"
    ];
  };
}
