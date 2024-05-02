if [ -n "$USE_PODMAN" ]; then
    DOCKER_EXEC=$(which podman)
else
    DOCKER_EXEC=$(which docker)
fi
if [ -n "$USE_PODMAN" ]; then
       CVW_MOUNT=$(pwd)/../../
fi
echo ${CVW_MOUNT}
USERNAME="cad"

UBUNTU_WALLY_HASH=$(${DOCKER_EXEC} images --quiet wallysoc/ubuntu_wally)
TOOLCHAINS_HASH=$(${DOCKER_EXEC} images --quiet wallysoc/toolchains_wally)
TOOLCHAINS_MOUNT=${TOOLCHAINS_MOUNT}

if [ -z $UBUNTU_WALLY_HASH ]; then
    echo "CANNOT FIND wallysoc/ubuntu_wally, please get the image first with \`get_image.sh\`";
    exit 1
else
    echo "Get ${UBUNTU_WALLY_HASH} for ubuntu_wally"
fi

if [ ! -z $TOOLCHAINS_MOUNT ]; then
    if [ -n "$QUESTA" ]; then
        ${DOCKER_EXEC} run -it --rm -v ${TOOLCHAINS_MOUNT}:/opt/riscv -v ${CVW_MOUNT}:/home/${USERNAME}/cvw -v ${QUESTA}:/cad/mentor/questa_sim-xxxx.x_x wallysoc/ubuntu_wally
    else
        ${DOCKER_EXEC} run -it --rm -v ${TOOLCHAINS_MOUNT}:/opt/riscv -v ${CVW_MOUNT}:/home/${USERNAME}/cvw wallysoc/ubuntu_wally
    fi
elif [ -z $TOOLCHAINS_HASH ]; then
    echo "CANNOT FIND wallysoc/toolchains_wally, please get the image first with \`get_image.sh\`";
    exit 1
else
    echo "Get ${TOOLCHAINS_HASH} for toolchains_wally"
    ${DOCKER_EXEC} run --user root -it --rm -v ${CVW_MOUNT}:/home/${USERNAME}/cvw wallysoc/toolchains_wally
fi

echo "Successfully reach the end"
