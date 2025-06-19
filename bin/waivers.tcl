#
# Synopsys SpyGlass Lint Waivers
# james.stine@okstate.edu 11 June 2025
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#

# Add waivers that are not neededed to be checked
waive -rule { W240 W528 W123 W287b }
# Add waiver for undriven outputs for items like Uncore
waive -du {  {rom1p1r} {uncore} } -rule {  {UndrivenInTerm-ML}  }

