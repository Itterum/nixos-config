{ pkgs, ... }:

{
  programs.zsh.enable = true;
  users.users.itterum.shell = pkgs.zsh;
}
