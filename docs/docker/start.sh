UBUNTU_WALLY_HASH=$(docker images --quiet wallysoc/ubuntu_wally)
TOOLCHAINS_HASH=$(docker images --quiet wallysoc/toolchains_wally)
TOOLCHAINS_MOUNT=${TOOLCHAINS_MOUNT}

if [ -z $UBUNTU_WALLY_HASH ]; then
    echo "CANNOT FIND wallysoc/ubuntu_wally, please get the image first with \`get_image.sh\`";
    exit 1
else
    echo "Get ${UBUNTU_WALLY_HASH} for ubuntu_wally"
fi

if [ ! -z $TOOLCHAINS_MOUNT ]; then
    docker run -it --rm -v ${TOOLCHAINS_MOUNT}:/opt/riscv wallysoc/ubuntu_wally
elif [ -z $TOOLCHAINS_HASH ]; then
    echo "CANNOT FIND wallysoc/toolchains_wally, please get the image first with \`get_image.sh\`";
    exit 1
else
    echo "Get ${TOOLCHAINS_HASH} for toolchains_wally"
    docker run -it --rm wallysoc/toolchains_wally
fi

echo "Successfully reach the end"
