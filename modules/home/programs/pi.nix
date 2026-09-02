{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];
  # programs.pi-coding-agent = {
  # enable = true;

  # extraPackages = with pkgs; [
  #   nodejs
  #   bun
  # ];

  # models = {
  #   providers = {
  #     ollama = {
  #       baseUrl = "http://127.0.0.1:11434/v1";
  #       api = "openai-completions";
  #       apiKey = "ollama";

  #       models = [
  #         {
  #           id = "";
  #           name = "";
  #         }
  #       ];
  #     };
  #   };
  # };
  # };
}
