FPGA_AXI_SDC_MODULE_VERSION = 1.0
# TODO This variable needs to change based on where the package
# contents are stored on each individual computer. Might parameterize
# this somehow.
FPGA_AXI_SDC_SITE =
FPGA_AXI_SDC_SITE_METHOD = local
FPGA_AXI_SDC_LICENSE = GPLv2

$(eval $(kernel-module))
$(eval $(generic-package))
