Installing Wally, RISC-V tools, and Imperas tests from source gives you maximum control, but has several disadvantages:

-Building the executables takes several hours.
-Linux is poorly standardized, and the build steps might not work on your version
-The source files are constantly changing, and the versions you download might not be compatible with this textbook flow.

Docker is a tools to run applications in a prepackaged container
including all of the operating system support required.  Wally offers
a ~30GB container image with the open-source tools pre-installed from
Section D.1. In particular, using the container solves the long build
time for gcc and the fussy installation of sail. The container runs on
any platform supporting Docker, including Windows and Mac as well as
Linux.  It can access files outside the container, including local
installation of CAD tools such as Questa, and a local clone of the
core-v-wally repository.

Docker can be run on most operating systems, including Linux, Windows,
and Mac. The Wally Docker container is hosted at DockerHub
(http://docker.io).

Podman is a more secure and easier-to-use variation of Docker for
Linux developed by RedHat.  Both Docker and Podman run the same
containers.

This directory has a copy of the file utilized to create the Docker
for the toolchain discussed in the text. To build this docker, you can
type the following where the last argument is the name where you want
to store your docker.

docker build -t docker.io/wallysoc/wally-docker:latest .

This can also be changed if you make a mistake by using the tag
command.  For example, if I wanted to change my docker from
wally-docker to wally-docker2, I would type:

docker tag wallysoc/wally-docker:latest docker.io/wallysoc/wally-docker2:latest

Once you build your docker, you can run it as given in the Readme.
However, you can also push it to DockerHub with the following command.

docker push docker.io/wallysoc/wally-docker:latest

To run your docker, you can type the following at a command prompt or
terminal.

docker run -it -p 8080:8080 docker.io/wallysoc/wally-docker


