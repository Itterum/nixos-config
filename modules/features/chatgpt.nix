{ self, inputs, ... }:

{
  flake.nixosModules.gptApp =
    { pkgs, ... }:
    let
      chatgpt = inputs.nixos-chatgpt.packages.${pkgs.system}.chatgpt;
      bundledPlugins = "${chatgpt}/lib/chatgpt/resources/plugins/openai-bundled";
    in
    {
      environment.systemPackages = [ chatgpt ];

      home-manager.users.itterum =
        { lib, ... }:
        {
          home.activation.prepareChatgptBundledPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [[ -n "$DRY_RUN_CMD" ]]; then
              echo "Would prepare writable ChatGPT bundled plugins"
            else
              marketplace_parent="$HOME/.codex/.tmp/bundled-marketplaces"
              marketplace_target="$marketplace_parent/openai-bundled"

              $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$marketplace_parent"

              source_bundle_id="$(${pkgs.coreutils}/bin/cat "${bundledPlugins}/.bundle-id")"
              target_bundle_id=""
              if [[ -f "$marketplace_target/.bundle-id" ]]; then
                target_bundle_id="$(${pkgs.coreutils}/bin/cat "$marketplace_target/.bundle-id")"
              fi

              if [[ "$source_bundle_id" != "$target_bundle_id" ]]; then
                marketplace_staging="$(${pkgs.coreutils}/bin/mktemp -d "$marketplace_parent/openai-bundled.activation-XXXXXX")"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -R "${bundledPlugins}/." "$marketplace_staging/"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX "$marketplace_staging"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf "$marketplace_target"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$marketplace_staging" "$marketplace_target"
              else
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX "$marketplace_target"
              fi

              for plugin in browser chrome; do
                source_plugin="${bundledPlugins}/plugins/$plugin"
                version="$(${pkgs.jq}/bin/jq -er '.version' "$source_plugin/.codex-plugin/plugin.json")"
                cache_parent="$HOME/.codex/plugins/cache/openai-bundled/$plugin"
                cache_target="$cache_parent/$version"

                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$cache_parent"
                if [[ ! -f "$cache_target/scripts/browser-service.mjs" ]]; then
                  cache_staging="$(${pkgs.coreutils}/bin/mktemp -d "$cache_parent/.activation-XXXXXX")"
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -R "$source_plugin/." "$cache_staging/"
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX "$cache_staging"
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf "$cache_target"
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$cache_staging" "$cache_target"
                else
                  $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+rwX "$cache_target"
                fi

                if [[ "$plugin" == "chrome" ]]; then
                  for extension_host in "$cache_target"/extension-host/linux/*/extension-host; do
                    if [[ -f "$extension_host" ]]; then
                      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod u+x "$extension_host"
                    fi
                  done
                fi

                $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$version" "$cache_parent/latest"
              done
            fi
          '';
        };
    };
}
