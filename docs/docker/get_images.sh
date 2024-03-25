UBUNTU_BUILD=${UBUNTU_BUILD:-0}
TOOLCHAINS_BUILD=${TOOLCHAINS_BUILD:-0}
DOCKER_EXEC=${DOCKER_EXEC-$(which podman)}

# if UBUNTU_BUILD is 0, then call function fetch_ubuntu_image
# otherwise, call function build_ubuntu_image
if [ $UBUNTU_BUILD -eq 0 ]; then
    ${DOCKER_EXEC} pull wallysoc/wally
else
    ${DOCKER_EXEC} build -t ubuntu_wally -f Dockerfile.ubuntu .
    ${DOCKER_EXEC} tag ubuntu_wally:latest wallysoc/ubuntu_wally:latest
fi

# if TOOLCHAINS_BUILD is 0, then call function fetch_toolchains_image
# otherwise, call function build_toolchains_image
if [ $TOOLCHAINS_BUILD -eq 0 ]; then
    ${DOCKER_EXEC} pull wallysoc/wally_toolchains
else
    ${DOCKER_EXEC} build -t wally_toolchains -f Dockerfile.builds .
    ${DOCKER_EXEC} tag wally_toolchains:latest wallysoc/wally_toolchains:latest
fi