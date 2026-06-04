#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# Prepare variables for later use
images=()
runtime_images=(
    "ghcr.io/stell0/grantora-api:0.1.0"
    "docker.io/library/postgres:16-alpine"
    "docker.io/bitnamilegacy/etcd:3.5"
    "docker.io/apache/apisix:3.10.0-debian"
)
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/nethserver}"
# Configure the image name
reponame="grantora"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-grantora container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-grantora; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-grantora -v "${PWD}:/usr/src:Z" docker.io/library/node:24.15.0-slim
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-grantora \
    sh -c "yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=cluster:accountconsumer traefik@node:routeadm node:portsadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${runtime_images[*]}" \
    --label="org.opencontainers.image.title=ns8-grantora" \
    --label="org.opencontainers.image.description=Grantora Agent Capability Gateway module for NethServer 8" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
