//=============================================================================
//                   ------->  Revision History  <------
//=============================================================================
//
//   Date     Who   Ver  Changes
//=============================================================================
// 14-Jun-24  DWW     1  Initial creation
//=============================================================================

/*
    Generates a number of AXI-write transactions
*/

module fill_ram # (parameter AW=32, parameter DW=512)
(
    input   clk, resetn,

    // This is the pattern that should be repeated across
    // each outgoing burst
    input[31:0] pattern,

    // The RDMX target address for the ABM
    input[31:0] abm_addr,

    // When this strobes high, we'll transmit an ABM
    input   start,
    
    // When this is high, we're idle and ready for a start command
    output  idle,

    //==================  This is an AXI4-master interface  ===================

    // "Specify write address"              -- Master --    -- Slave --
    output reg [AW-1:0]                     M_AXI_AWADDR,
    output                                  M_AXI_AWVALID,
    output     [7:0]                        M_AXI_AWLEN,
    output     [2:0]                        M_AXI_AWSIZE,
    output     [3:0]                        M_AXI_AWID,
    output     [1:0]                        M_AXI_AWBURST,
    output                                  M_AXI_AWLOCK,
    output     [3:0]                        M_AXI_AWCACHE,
    output     [3:0]                        M_AXI_AWQOS,
    output     [2:0]                        M_AXI_AWPROT,
    input                                                   M_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output reg [DW-1:0]                     M_AXI_WDATA,
    output     [(DW/8)-1:0]                 M_AXI_WSTRB,
    output                                  M_AXI_WVALID,
    output                                  M_AXI_WLAST,
    input                                                   M_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              M_AXI_BRESP,
    input                                                   M_AXI_BVALID,
    output                                  M_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output reg [AW-1:0]                     M_AXI_ARADDR,
    output reg                              M_AXI_ARVALID,
    output     [2:0]                        M_AXI_ARPROT,
    output                                  M_AXI_ARLOCK,
    output     [3:0]                        M_AXI_ARID,
    output     [7:0]                        M_AXI_ARLEN,
    output     [1:0]                        M_AXI_ARBURST,
    output     [3:0]                        M_AXI_ARCACHE,
    output     [3:0]                        M_AXI_ARQOS,
    input                                                   M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW-1:0]                                           M_AXI_RDATA,
    input                                                   M_AXI_RVALID,
    input[1:0]                                              M_AXI_RRESP,
    input                                                   M_AXI_RLAST,
    output                                  M_AXI_RREADY
    //==========================================================================

);

// This is the total size of the ABM in bytes (1 MB)
localparam ABM_SIZE = 32'h10_0000;

// Each AXI burst is 4K bytes
localparam BURST_SIZE = 32'h1000;

// This is the number of bursts it takes to send the entire ABM
localparam BURST_COUNT = ABM_SIZE / BURST_SIZE;

// The number of data-cycles in a single burst
localparam CYCLES_PER_BURST = BURST_SIZE / (DW/8);

// State of the state machine that controls the AW-channel
reg awsm_state;

// State of the state machine that controls the W-channel
reg wsm_state;

// Burst counters for the AW and W channels
reg[15:0] aw_burst, w_burst;

// Counts data-beats for the W-channel
reg[7:0] beat;

// We're always ready to receive write-acknowledgements
assign M_AXI_BREADY = 1;

// We're idle when we're waiting around for a "start" to happen
assign idle = (start == 0) & (awsm_state == 0) & (wsm_state == 0);

//=============================================================================
// This state machine controls the AW channel.
//
// When "start" goes high, it will output BURST_COUNT write-requests
//=============================================================================
assign M_AXI_AWLEN   = CYCLES_PER_BURST - 1;
assign M_AXI_AWSIZE  = $clog2(DW/8);
assign M_AXI_AWBURST = 1; /* Burst type = Increment */
assign M_AXI_AWID    = 0;
assign M_AXI_AWLOCK  = 0;
assign M_AXI_AWCACHE = 0;
assign M_AXI_QOS     = 0;
assign M_AXI_AWWPROT = 0;
assign M_AXI_AWVALID = (resetn == 1) & (awsm_state == 1);
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    
    if (resetn == 0) begin
        awsm_state <= 0;
    end

    else case(awsm_state)

        0:  if (start) begin
                aw_burst      <= 1;
                M_AXI_AWADDR  <= abm_addr;
                awsm_state    <= 1;
            end

        1:  if (M_AXI_AWVALID & M_AXI_AWREADY) begin
                M_AXI_AWADDR <= M_AXI_AWADDR + BURST_SIZE;
                if (aw_burst < BURST_COUNT)
                    aw_burst   <= aw_burst + 1;
                else
                    awsm_state <= 0;
            end

    endcase

end
//=============================================================================



//=============================================================================
// This state machine controls the W-channel
//=============================================================================
assign M_AXI_WSTRB  = -1;
assign M_AXI_WLAST  = (beat == (CYCLES_PER_BURST - 1));
assign M_AXI_WVALID = (resetn == 1) & (wsm_state == 1);
//-----------------------------------------------------------------------------
always @(posedge clk) begin
    
    if (resetn == 0) begin
        wsm_state  <= 0;
    end else case (wsm_state)

        0:  if (start) begin
                w_burst      <= 1;
                beat         <= 0;
                wsm_state    <= 1;
            end

        1:  if (M_AXI_WVALID & M_AXI_WREADY) begin
                beat <= beat + 1;
                if (M_AXI_WLAST) begin
                    beat <= 0;
                    if (w_burst < BURST_COUNT)
                        w_burst <= w_burst + 1;
                    else
                        wsm_state  <= 0;
                end

            end

    endcase
end
//=============================================================================


//=============================================================================
// On even numbered beats, the high-order 16-bits of "pattern" are repeated
// across M_AXI_WDATA.
//
// On odd numbered beats, the low-order 16-bits of "pattern" are repeated
// across M_AXI_WDATA
//=============================================================================
wire[7:0] a = pattern[31:24];
wire[7:0] b = pattern[23:16];
wire[7:0] c = pattern[15:08];
wire[7:0] d = pattern[07:00];
always @* begin
    if (beat[0] == 0)
        M_AXI_WDATA = {(DW/16){b, a}};
    else
        M_AXI_WDATA = {(DW/16){d, c}};
end
//=============================================================================


endmodule
