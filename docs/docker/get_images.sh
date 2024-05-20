UBUNTU_BUILD=${UBUNTU_BUILD:-0}
TOOLCHAINS_BUILD=${TOOLCHAINS_BUILD:-0}

if [ -n "$USE_PODMAN" ]; then
    DOCKER_EXEC=$(which podman)
else
    DOCKER_EXEC=$(which docker)
fi

if [ $UBUNTU_BUILD -eq 1 ]; then
    ${DOCKER_EXEC} build -t ubuntu_wally -f Dockerfile.ubuntu .
    ${DOCKER_EXEC} tag ubuntu_wally:latest wallysoc/ubuntu_wally:latest
else
    ${DOCKER_EXEC} pull wallysoc/ubuntu_wally
fi

if [ $TOOLCHAINS_BUILD -eq 1 ]; then
    `which python` get_buildroot_testvector.py
    ${DOCKER_EXEC} build -t toolchains_wally -f Dockerfile.builds .
    ${DOCKER_EXEC} tag toolchains_wally:latest wallysoc/toolchains_wally:latest
else
    ${DOCKER_EXEC} pull wallysoc/toolchains_wally
fi