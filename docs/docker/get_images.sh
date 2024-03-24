UBUNTU_BUILD=${UBUNTU_BUILD:-0}
TOOLCHAINS_BUILD=${TOOLCHAINS_BUILD:-0}

# if UBUNTU_BUILD is 0, then call function fetch_ubuntu_image
# otherwise, call function build_ubuntu_image
if [ $UBUNTU_BUILD -eq 0 ]; then
    docker pull wallysoc/ubuntu_wally
else
    docker build -t ubuntu_wally -f Dockerfile.ubuntu .
    docker tag ubuntu_wally:latest wallysoc/ubuntu_wally:latest
fi

# if TOOLCHAINS_BUILD is 0, then call function fetch_toolchains_image
# otherwise, call function build_toolchains_image
if [ $TOOLCHAINS_BUILD -eq 0 ]; then
    docker pull wallysoc/wally_toolchains
else
    docker build -t wally_toolchains -f Dockerfile.builds .
    docker tag wally_toolchains:latest wallysoc/wally_toolchains:latest
fi