# Consistant Build of Toolchain for Wally

`Dockerfile.*` contains a ~~multi-stage~~ build for all the toolchains that are required for Wally's open-source features.

## TODOs

- [ ] Pinning the tools version
    - As for the consistent tool build, should we use specific versions of tools in order to avoid bugs at the master branch?
    - And we will upgrade the versions of tool after a certain period of time to get the latest features and patches while verifying it won’t cause any problem.
- [ ] Mount the EDA Tools and Path
- [x] Enable X11 forwarding for docker
    - `--network=host` for docker run
    - `xhost +localhost:${USER}` for host

## TL;DR

Files at this folder can help you to build/fetch environment you need to run wally with the help of Docker.

Here are some common use cases, read the following text for other configuration:

```shell
# For HMC students, /opt/riscv is available and nothing needs to be built, skip this file

# For those with all the toolchains installed, simply mount the toolchains
TOOLCHAINS_MOUNT=<path-to-toolchains> ./start

# For those have nothing, fetching the builds are easiest thing
./start

# For other cases, checkout start-up script for building option
```

## New Dockerfile Design

There are two parts of the new docker-related design:

- build proper image(s)
- set up start-up script

### Problem Statement

The following 3 problems are to be resolved:

- remove storage of useless files with `Dockerfile`
    - git build: clean up
    - packages info
        - apt: `apt-get clean`
        - pip: `--no-cache-dir`
- reuse storage
    - read-only $RISCV volume across different users with `docker image`
    - local-built RISCV with `start-up script`
- use commercial EDA tools: optional environment variable configuration with `start-up script`

### Dockerfiles

There are two Dockerfiles:

- `Dockerfile.ubuntu`: basic ubuntu system setup and produce `ubuntu_wally` image in docker
    - corresponds to `wallysoc/ubuntu_wally`
- `Dockerfile.builds`: all the required toolchains are built
    - corresponds to `wallysoc/toolchains_wally`

Because we are going to use the whole environment of ubuntu to get both executables and python packages, we are not going to use multi-stage builds, which runs only executables.

### Scripts

There are two scripts:

- `get_images.sh`: get docker image `wallysoc/ubuntu_wally` or `wallysoc/toolchains_wally`
- `start.sh`: start running the container

#### Image Building Script

Options (if you want to build the images):

- UBUNTU_BUILD: value other than 0
- TOOLCHAINS_BUILD: value other than 0

#### Start-up Script

There are two settings:

- build/fetch both ubuntu_wally and toolchains in docker image and use it
- build/fetch only ubuntu_wally and use local toolchains folder

Options:

- ubuntu_wally: fetch by default
    - build: UBUNTU_BUILD=1
- toolchains: fetch by default
    - build: TOOLCHAINS_BUILD=1
    - use local toolchain: TOOLCHAINS_MOUNT

### Commercial EDA Tools

This is kind of tricky, because Docker network is a different network from the host. Therefore, it should be carefully handled in order to use the host's license server while minimizing the access of docker container.

There are at least two ways to solve this problem:

- use `--network=host` in docker-run to use the same network
- (NOT WORKING) use bridge in docker-run while forwarding docker network's traffic to localhost without setting `X11UseLocalhost no`
    - this idea is from https://stackoverflow.com/a/64284364/10765798

## Old Dockerfile Analysis

> Refer to https://github.com/openhwgroup/cvw/blob/91919150a94ccf8e750cf7c9eec1c400efaef7f5/docs/Dockerfile

There are stages in the old Dockerfile:

- debian-based package installtion
    - apt package
    - python3 package
- user and its group configuration
- clone and build toolchain with prefix=$RISCV
    - riscv-gnu-toolchain
    - elf2hex
    - qemu
    - spike
    - sail
    - buildroot

## References

- Dockerfile Docs: https://docs.docker.com/reference/dockerfile/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Best Practices: https://docs.docker.com/develop/develop-images/guidelines/
- Chinese Reference: https://yeasy.gitbook.io/docker_practice/
- Clean Cache
    - apt cache: https://gist.github.com/marvell/7c812736565928e602c4
    - pip cache: https://stackoverflow.com/questions/50333650/install-python-package-in-docker-file
- Docker Network: https://docs.docker.com/network/
