#!/usr/bin/env bash
# for details on factorio dedicated servers see https://satisfactory.wiki.gg/wiki/Dedicated_servers
# for details on steamcmd see https://developer.valvesoftware.com/wiki/SteamCMD

# Set to `-x` for Debug logging
set +x

function install_steamcmd () {
    if [ ! -e "${steam_cmd}" ] ; then
      printf "\n### install steamcmd...\n"
      pushd $steam_path
      curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
      popd
      printf "\n### steamcmd installed.\n"
    fi
}

# Update the Satisfactory server
function update_satisfactory() {
    printf "\n### Updating Satisfactory Server...\n"
    
    # run script
    $steam_cmd +login anonymous +app_update 1690800 validate +quit

    printf "\n### Satisfactory Server updated.\n"
}

# Start the Satisfactory Server
function start_satisfactory() {
    printf "\n### Starting Satisfactory Server...\n"
    $base_game_dir/FactoryServer.sh -log -unattended
}

## Main
install_steamcmd
update_satisfactory
start_satisfactory
