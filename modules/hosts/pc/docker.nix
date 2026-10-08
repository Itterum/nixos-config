{ ... }:

{
  flake.nixosModules.pcDocker = {
    virtualisation.docker.enable = true;

    users.users.itterum.extraGroups = [ "docker" ];
  };
}
