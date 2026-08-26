{ ... }:

{
  programs.dms-shell.enable = true;

  services.displayManager = {
    defaultSession = "niri";
    autoLogin.enable = false;

    dms-greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/itterum";
      logs.save = true;
    };
  };
}
