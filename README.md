# Satisfactory Rootless Dedicated Server

- [Satisfactory Rootless Dedicated Server](#satisfactory-rootless-dedicated-server)
  - [Build Requires](#build-requires)
    - [READ UP ON BUILDAH AND PODMAN](#read-up-on-buildah-and-podman)
  - [Build Container](#build-container)
  - [Container requirements](#container-requirements)
    - [Create a regular user](#create-a-regular-user)
    - [Created persistend storage folders](#created-persistend-storage-folders)
    - [Change the storage folders owner](#change-the-storage-folders-owner)
  - [Manual container stopping and starting](#manual-container-stopping-and-starting)
    - [Starting](#starting)
    - [Stopping](#stopping)
  - [Automatic container stopping and starting](#automatic-container-stopping-and-starting)
    - [Enable linger](#enable-linger)
    - [Add unit file](#add-unit-file)
    - [Update the systemd unit files](#update-the-systemd-unit-files)
    - [Enable the unit file](#enable-the-unit-file)
    - [Start the container](#start-the-container)
  - [Check the container logs](#check-the-container-logs)
  - [Commands you might also use](#commands-you-might-also-use)
    - [Stopping the container](#stopping-the-container)
    - [Disable automatic starting](#disable-automatic-starting)
      - [lazy admin commands](#lazy-admin-commands)
    - [Security hardened user option](#security-hardened-user-option)

## Build Requires

- podman latest
- buildah latest

### READ UP ON BUILDAH AND PODMAN

For podman and buildah installation and usage visit <https://github.com/containers/buildah/blob/main/install.md>  
Make sure you also configure subuid and subgid.  
For details on subuid and subgid visit <https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md>

## Build Container

To build run the build.sh script

## Container requirements

On the container host

### Create a regular user

On your linux system as root create a regular user.  
The userid (UID) and the groupid (GID) are not important as we run a rootless container.  
Make sure the subuid and subgid are configured for this user for details visit <https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md>

This tutorial will assume you are using fedora linux and the user will be called steam with a regular home and set a password on it

> I choose to name the user **on the container-host** steam, this is a random name that just happens to be the same as the user **in the container**.
Podman will assign an unique uid/gid when it starts the container and will try to do it's best to avoid conflicts with any uid specyfied in the /etc/passwd and /etc groups **of the container host**.
So you might as well call it qwerty, just make sure you issue all the commands as the user qwerty after that.

```bash
useradd -m steam
passwd steam
```

### Created persistend storage folders

Since the container is ephemeral (ie all the savegame and server data in it will be gone when it shuts down) you must create persistent storage to be used as a savegame location and server data location.  
The simplest way to do this is by creating 2 directories and mounting these as a volume in the container.

As the steam user create 2 directories, one for the server and one for savegames.

```bash
mkdir /path/to/SatisfactoryDedicatedServer /path/to/SaveGames
```

These will be mounted as volumes when the container is started

### Change the storage folders owner

The rootless container will use a different uid/gid than the one that is linked to the steam user.  
To make the storage folders writeable for that uid/gid we must change the owner of the folder using the podman unshare command.  

```bash
podman unshare chown -R 1000:1000 /path/to/SatisfactoryDedicatedServer
podman unshare chown -R 1000:1000 /path/to/SaveGames
```

The uid/gid of the directories and subdirectories (if any) will now be changed to a random number from the subuid/subgid range.
The steam user can now only read those directories (not write)

## Manual container stopping and starting

### Starting

To start issue the following command as the steam user.

```bash
/usr/bin/podman run --replace -d  \
  -v /path/to/SatisfactoryDedicatedServer:/home/steam/Steam:Z \
  -v /path/to/SaveGames:/home/steam/.config/Epic/FactoryGame/Saved/SaveGames:Z \
  --publish 7777:7777/udp \
  --publish 7777:7777/tcp \
  --name satisfactory-server satisfactory-server:latest
```

The ```:Z``` ensures that podman will adjust the selinux context and owner of the directories to that of the userid and groupid used by the rootless container.

The steam user will have no more write access to the directories after the pod has run once.
If you wish to remove the directories afterwards you need to do this as root.

### Stopping

As the steam user run the following command to stop the server.

```bash
/usr/bin/podman stop satisfactory-server
```

## Automatic container stopping and starting

- [Enable linger for the steam user as root](#enable-linger)
- [Add unit file to the steam user home dir](#add-unit-file)
- [Update systemd unit files as user](#update-the-systemd-unit-files)
- [Enable unit file as the steam user](#enable-the-unit-file)
- [Start unit file as the steam user](#starting)

### Enable linger

To autostart the container on boot by systemd as a regular user, the user must have linger enabled on it's account.
Enabling linger on a user account can only be done with root privileges.

```bash
sudo loginctl enable-linger steam
```

### Add unit file

Systemd needs a unit file to autostart a container, for a single user it needs to be located in the home directory of the user in a subfolder of the ```.config``` directory

```bash
mkdir -p /home/steam/.config/systemd/user
cp container-satisfactoryserver.service /home/steam/.config/systemd/user/
```

Edit the paths ```/path/to``` in the unitfile to match the ones on your system

### Update the systemd unit files

Systemd needs to be made aware of the new unit files.
This can be done by issueing the following command as the steam user.

```bash
systemctl --user daemon-reload
```

Or you can reboot the system

tab-completion works now because we did a 'systemctl --user daemon-reload'

### Enable the unit file

As the steam user

```bash
systemctl --user enable container-satisfactoryserver.service
```

Now the container will be started on system boot

### Start the container

As the steam user

```bash
systemctl --user start container-satisfactoryserver.service
```

## Check the container logs

To tail the logs of the container
As the steam user

```bash
podman logs -f satisfactory-server
```

## Commands you might also use

Some more commands that you might wis to use but that are no needed to get the container automatically started.

### Stopping the container

As steam user stop the container

```bash
systemctl --user stop container-satisfactoryserver.service
```

### Disable automatic starting

To disable the automatic starting of the container

```bash
systemctl --user disable container-satisfactoryserver.service
```

#### lazy admin commands

As steam user enable autostart and start the container

```bash
systemctl --user enable --now container-satisfactoryserver.service
```

As steam user stop and disable autostart of the container

```bash
systemctl --user disable --now container-satisfactoryserver.service
```

### Security hardened user option

This is optional!!  
You could make the steam user more secure if you do the following,
but this makes using the account a bit more difficult

Create the user with the nologin shell

```bash
useradd -m -s /sbin/nologin steam
```

Do not set a password on the account

Then if you wish to access the account to do things like enableing the container at boot.
Using your own regular account on the container host

```bash
sudo su - steam
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
```

Now all the systemctl and podman commands will work.
