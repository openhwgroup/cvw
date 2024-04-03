# Consistant Build of Toolchain for Wally

`Dockerfile.*` contains a ~~multi-stage~~ build for all the toolchains that are required for Wally's open-source features.

## TODOs

- [ ] Pinning the tools version
    - As for the consistent tool build, should we use specific versions of tools in order to avoid bugs at the master branch?
    - And we will upgrade the versions of tool after a certain period of time to get the latest features and patches while verifying it won’t cause any problem.
- [x] Mount the ~~EDA Tools~~QuestaSIM and Path
    - USE_QUESTA and QUESTA for path
- [x] Enable X11 forwarding for docker
    - `--network=host` for docker run
    - `xhost +localhost:${USER}` for host
- [ ] Regression Script
- [ ] Configure the license for Questa

## TL;DR

Steps:

1. Install either Docker Engine or Podman for container support
2. Run start-up script `docs/docker/start.sh` to start a stateless container to run the toolchains and EDA tool

### Docker Engine or Podman

First and foremost, install either Docker Engine or Podman:

- Docker Engine (More Popular, default): https://docs.docker.com/engine/install/
- Podman: https://podman.io/docs/installation

Here are some common installation commands (not guarantee to be up to date)

```shell
# For Ubuntu
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Installation
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Hello-World Example
docker run hello-world
```

### Use of Start-up Script

Files at this folder can help you to build/fetch environment you need to run wally with the help of Docker.

Here are some common use cases, it will provides you an environment with RISC-V toolchains that required by this project:

```shell
# By default, we assume that you have cloned the cvw respository and running the script at relative path `docs/docker`

# For HMC students, /opt/riscv is available and nothing needs to be built
TOOLCHAINS_MOUNT=/opt/riscv QUESTA=/cad/mentor/questa_sim-2023.4 ./start.sh

# For those with all the toolchains installed, simply mount the toolchains
TOOLCHAINS_MOUNT=<path-to-toolchains> ./start.sh

# For those have nothing, fetching the builds are easiest thing
CVW_MOUNT=<path-to-cvw> ./start.sh
# if you want to use Podman instead of Docker Engine
USE_PODMAN=1 ./start.sh

# For other cases, checkout start-up script for building option
```
For further usage, please consult the following configuration.

## Conventions

- In the container
    - default user is `cad`
    - RISCV is defined as `/opt/riscv`
    - QUESTA is defined as `/cad/mentor/questa_sim-xxxx.x_x`
        - bin location is in `$QUESTA/questasim/bin`
    - cvw folder should be mounted on `/home/${USERNAME}/cvw`
        - as for `cad`, it is `/home/cad/cvw`
- In the current shell environment: checkout the constants in the following script section

## New Dockerfile Design

There are two parts of the new docker-related design:

- build proper image(s)
- scripts for different purposes

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

There are four scripts:

- `start.sh` (most often used): start running the container
    - if you don't care about toolchains and running regression automatically, this script is only thing you need to know
- `get_images.sh`: get docker image `wallysoc/ubuntu_wally` or `wallysoc/toolchains_wally`
- `run_regression.sh`: run regressions with Verilator (and QuestaSIM) on specific CVW
- `test.sh`: a test script to facilitate the above three

All the following options in the corresponding scripts should be set by either:

- define it right before the command: `USE_PODMAN=1 ./start.sh` with USE_PODMAN on start-up script
    - the variable is only effective for the current command, not the following environment
- declare it globally and use it any time afterwards:

```shell
# declare it globally in the environment
export DOCKER_EXEC=$(which docker)
export UBUNTU_BUILD=1

# run the script with all the above variables
./get_images.sh
```

#### Start-up Script: start.sh

There are two settings:

- build/fetch both ubuntu_wally and toolchains in docker image and use it
- build/fetch only ubuntu_wally and use local toolchains folder

Options:

- USE_PODMAN:
    - by default, docker is used
    - set USE_PODMAN=1 otherwise
- UBUNTU_BUILD:
    - fetch by default
    - set UBUNTU_BUILD=1 if you want to build with Dockerfile.ubuntu
- TOOLCHAINS_BUILD:
    - fetch by default
    - set TOOLCHAINS_BUILD=1 if you want to build with Dockerfile.build

#### Image Building Script: get_images.sh

Options (if you want to build the images):

- DOCKER_EXEC:
    - docker by default
    - if you want to use podman, then set it to $(which podman)
- UBUNTU_BUILD: value other than 0 if you want to build it instead of fetching it
- TOOLCHAINS_BUILD: value other than 0 if you want to build it instead of fetching it

#### Regression Script: run_regression.sh

There are two parts for regression:

- Verilator: must be able to run as it is open-sourced
- Questa: OPTIONAL as it is commercial EDA Tool

Options:

- RUN_QUESTA: false by default
    - QUESTA: home folder for mounted QuestaSIM `/cad/mentor/questa_sim-xxxx.x_x` if enabled
    - for example, if your vsim is in `/cad/mentor/questa_sim-2023.4/questasim/bin/vsim` then your local QuestaSIM folder is `/cad/mentor/questa_sim-2023.4`, so you have to add `-v /cad/mentor/questa_sim-2023.4:/cad/mentor/questa_sim-xxxx.x_x -e RUN_QUESTA=1`

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
    - riscv-gnu-toolchain: https://github.com/riscv-collab/riscv-gnu-toolchain
    - elf2hex: https://github.com/sifive/elf2hex
    - qemu: https://github.com/qemu/qemu
    - spike: https://github.com/riscv-software-src/riscv-isa-sim
    - sail: https://github.com/riscv/sail-riscv/commits/master/
    - buildroot: https://github.com/buildroot/buildroot
    - verilator: https://github.com/verilator/verilator

### Tool Versions till 20240331

- riscv-gnu-toolchain: `2024.03.01`
- elf2hex: `f28a3103c06131ed3895052b1341daf4ca0b1c9c`
- qemu: not tested
- spike: `3427b459f88d2334368a1abbdf5a3000957f08e8`
- sail: `f601c866153c79a7ae8404f939dc2d66aa2e41f9`
- buildroot: `2021.05`
- verilator: `v5.022`

## References

- Dockerfile Docs: https://docs.docker.com/reference/dockerfile/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Best Practices: https://docs.docker.com/develop/develop-images/guidelines/
- Chinese Reference: https://yeasy.gitbook.io/docker_practice/
- Clean Cache
    - apt cache: https://gist.github.com/marvell/7c812736565928e602c4
    - pip cache: https://stackoverflow.com/questions/50333650/install-python-package-in-docker-file
- Docker Network: https://docs.docker.com/network/
