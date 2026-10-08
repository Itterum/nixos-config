{ ... }:

{
  flake.homeModules.github = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings."github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
      };
    };
  };
}
