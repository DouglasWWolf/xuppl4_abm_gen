module status_leds
(
    input qsfp0_up, qsfp1_up,

    output[3:0] led_green_l, led_orange_l
);

assign led_orange_l = { 1'b1, 1'b1,  qsfp1_up,  qsfp0_up};
assign led_green_l  = { 1'b1, 1'b1, ~qsfp1_up, ~qsfp0_up};

endmodule