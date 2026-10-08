{ ... }:

{
  flake.nixosModules.pcSunshine = {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = false;
    };

    services.avahi.openFirewall = true;

    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr 192.168.100.0/24 tcp dport { 47984, 47989, 47990, 48010 } accept comment "Sunshine from home LAN"
      ip saddr 192.168.100.0/24 udp dport { 47998, 47999, 48000, 48002, 48010 } accept comment "Sunshine from home LAN"
    '';
  };
}
