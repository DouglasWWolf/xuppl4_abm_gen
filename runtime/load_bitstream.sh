filename=$1
test -z $filename && filename=xuppl4_abm_gen.bit
load_bitstream -hot_reset -part xcvu3p_0 -pci_device 10ee:903f -vivado "$VIVADO" $filename
