#!/bin/bash

#
# Generate minimal container image
#

set -ex

function set_vars () {
  version=1.5
  fedora_version=40
  registry=registry.tjako.thuis:9999/library
  containername=satisfactory-server
  
}

function clean_up () {
  if  [ -n "$(podman ps -qa)" ] ; then podman rm $(podman ps -qa) --force ; fi
  podman image prune --force
}

function build_container () {
  fedora_version=$fedora_version tag=$registry/$containername:$version buildah unshare bash build_container.sh
}

set_vars
build_container
clean_up
