################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name pcie_refclk_clk_p -period 10 [get_ports pcie_refclk_clk_p]
create_clock -name qsfp0_clk_clk_p -period 3.103 [get_ports qsfp0_clk_clk_p]
create_clock -name qsfp1_clk_clk_p -period 3.103 [get_ports qsfp1_clk_clk_p]

################################################################################