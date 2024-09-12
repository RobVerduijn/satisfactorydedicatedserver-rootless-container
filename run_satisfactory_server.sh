#!/usr/bin/env bash
# for details on factorio dedicated servers see https://satisfactory.wiki.gg/wiki/Dedicated_servers
# for details on steamcmd see https://developer.valvesoftware.com/wiki/SteamCMD

# Set to `-x` for Debug logging
set +x
function set_variables() {
    printf "\n### Setting variables...\n"
    maxplayers="${maxplayers:4}"
    steam_path="${HOME}/Steam"
    steam_cmd="${steam_path}/steamcmd.sh"
    base_game_dir="${steam_path}/steamapps/common/SatisfactoryDedicatedServer"
    config_dir="${base_game_dir}/FactoryGame/Saved/Config/LinuxServer"
}

function install_steamcmd () {
    if [ ! -e "${steam_cmd}" ] ; then
      printf "\n### install steamcmd...\n"
      pushd $steam_path
      curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
      popd
      printf "\n### steamcmd installed.\n"
    fi
}

function set_maxplayers () {
    # installing crudini would increase the image size by 50%, so we work with sed
    printf "\n### Setting MaxPlayers to $maxplayers...\n"
    # create config dir if it does not exist
    if [ ! -e $configdir ] && mkdir -p $configdir
    # create Game.ini if it does not exist
    if [ ! -e $configdir/Game.ini ] ; then touch $configdir/Game.ini ; fi
    # Add Section and maxplayers if section does not exist
    if ! grep -q '\[/Script/Engine.GameSession]' $configdir/Game.ini ; then
        echo >> $configdir/Game.ini
        echo '[/Script/Engine.GameSession]' >> $configdir/Game.ini
        echo "MaxPlayers=$maxplayers" >> $configdir/Game.ini
    else
    # Add maxplayers if it does not exist
    if ! grep -q MaxPlayers= $configdir/Game.ini; then
        sed -i "/\[\/Script\/Engine.GameSession\]/a MaxPlayers=$maxplayers" $configdir/Game.ini
    else
        # Set maxplayers if it exists
        sed -i "s/MaxPlayers=.*/MaxPlayers=$maxplayers/" $configdir/Game.ini
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
set_variables
install_steamcmd
update_satisfactory
start_satisfactory
