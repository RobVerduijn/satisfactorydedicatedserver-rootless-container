# see: https://satisfactory.wiki.gg/wiki/Dedicated_servers
# see 

# start new container from scratch
set -x
# from scratch is the smallest form of parent container, ie: nothing at all
container=$(buildah from scratch)
mnt=$(buildah mount $container)

# only install the bare essentials needed to run steamcmd
dnf install --installroot $mnt -y --nogpgcheck --releasever $fedora_version --nodocs --setopt install_weak_deps=False tar gzip glibc.i686 libstdc++.i686 curl findutils
dnf clean all --installroot $mnt
# account name, uid and gid can be anything, but I chose steam, 1000, 1000 because I'm totally devoid of creativity
echo 'steam:x:1000:' >> $mnt/etc/group
echo 'steam:*:19749:0:99999:7:::' >> $mnt/etc/shadow
echo 'steam:x:1000:1000:Steam User:/home/steam:/bin/bash' >> $mnt/etc/passwd
# I could use force install dir to create a shorter path, 
# but this is a container, so there will be no other gameservers in it,
# I am going to start it with a unit service file so I never need to type it,
# therefore I won't use it.
mkdir -p $mnt/home/steam/Steam $mnt/home/steam/.config/Epic/FactoryGame/Saved/SaveGames
chown -R 1000:1000 $mnt/home/steam
# I think the following are self explanatory ...if not read the man page of buildah
buildah umount $container
buildah copy --chown 1000:1000 $container run_satisfactory_server.sh /home/steam
buildah config --user steam $container
buildah config --workingdir /home/steam $container
buildah config --entrypoint '/bin/bash /home/steam/run_satisfactory_server.sh' $container
# squash reduces image size by removing all layers
buildah commit --squash $container $tag
