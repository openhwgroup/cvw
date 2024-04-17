QUESTA_HOME?=/cad/mentor/questa_sim-2023.4
CVW_GIT?=""

commanline:
	podman run -it --rm \
    -v cvw_temp:/home/cad/cvw \
    -v $(QUESTA_HOME):/cad/mentor/questa_sim-xxxx.x_x \
    --privileged --network=host \
    wallysoc/regression_wally /bin/bash

regression_openhw_cvw:
	podman run \
	-e CVW_GIT=$(CVW_GIT) \
    -e CLEAN_CVW=1 -e BUILD_RISCOF=1 -e RUN_QUESTA=1 \
    -v cvw_temp:/home/cad/cvw \
    -v $(QUESTA_HOME):/cad/mentor/questa_sim-xxxx.x_x \
    --privileged --network=host \
    --rm wallysoc/regression_wally