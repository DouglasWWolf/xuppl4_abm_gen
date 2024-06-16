module qsfp_pins
(
    // Active-low reset to the QSFP transceiver module
    output[1:0] qsfp_rst_l,

    // Active-high "low power" setting for the QSFP transceiver module
    output[1:0] qsfp_lp
);

assign qsfp_rst_l = 2'b11;
assign qsfp_lp    = 2'b00;

endmodule
