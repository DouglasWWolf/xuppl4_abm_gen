//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 12-Jul-24  DWW     1  Initial creation
//====================================================================================

/*
    This moves a block of data from a source AXI-MM interface to a destination
    AXI-MM interface.

    Data widths of the two interfaces must match.
*/


module dma_abm_to_rdmx # (parameter DW = 512, parameter AW = 64)
(
    input       clk, resetn,
    input[63:0] src_address,
    input       start,
    output      idle,

    //=================  This is the source AXI4-master interface  ================

    // "Specify write address"              -- Master --    -- Slave --
    output     [AW-1:0]                     SRC_AXI_AWADDR,
    output                                  SRC_AXI_AWVALID,
    output     [7:0]                        SRC_AXI_AWLEN,
    output     [2:0]                        SRC_AXI_AWSIZE,
    output     [3:0]                        SRC_AXI_AWID,
    output     [1:0]                        SRC_AXI_AWBURST,
    output                                  SRC_AXI_AWLOCK,
    output     [3:0]                        SRC_AXI_AWCACHE,
    output     [3:0]                        SRC_AXI_AWQOS,
    output     [2:0]                        SRC_AXI_AWPROT,
    input                                                   SRC_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output     [DW-1:0]                     SRC_AXI_WDATA,
    output     [(DW/8)-1:0]                 SRC_AXI_WSTRB,
    output                                  SRC_AXI_WVALID,
    output                                  SRC_AXI_WLAST,
    input                                                   SRC_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              SRC_AXI_BRESP,
    input                                                   SRC_AXI_BVALID,
    output                                  SRC_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output     [AW-1:0]                     SRC_AXI_ARADDR,
    output                                  SRC_AXI_ARVALID,
    output     [2:0]                        SRC_AXI_ARPROT,
    output                                  SRC_AXI_ARLOCK,
    output     [3:0]                        SRC_AXI_ARID,
    output     [2:0]                        SRC_AXI_ARSIZE,
    output     [7:0]                        SRC_AXI_ARLEN,
    output     [1:0]                        SRC_AXI_ARBURST,
    output     [3:0]                        SRC_AXI_ARCACHE,
    output     [3:0]                        SRC_AXI_ARQOS,
    input                                                   SRC_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW-1:0]                                           SRC_AXI_RDATA,
    input                                                   SRC_AXI_RVALID,
    input[1:0]                                              SRC_AXI_RRESP,
    input                                                   SRC_AXI_RLAST,
    output                                  SRC_AXI_RREADY,
    //==========================================================================


    //============= This is the destination AXI4-master interface  =============

    // "Specify write address"              -- Master --    -- Slave --
    output     [AW-1:0]                     DST_AXI_AWADDR,
    output                                  DST_AXI_AWVALID,
    output     [7:0]                        DST_AXI_AWLEN,
    output     [2:0]                        DST_AXI_AWSIZE,
    output     [3:0]                        DST_AXI_AWID,
    output     [1:0]                        DST_AXI_AWBURST,
    output                                  DST_AXI_AWLOCK,
    output     [3:0]                        DST_AXI_AWCACHE,
    output     [3:0]                        DST_AXI_AWQOS,
    output     [2:0]                        DST_AXI_AWPROT,
    input                                                   DST_AXI_AWREADY,

    // "Write Data"                         -- Master --    -- Slave --
    output     [DW-1:0]                     DST_AXI_WDATA,
    output     [(DW/8)-1:0]                 DST_AXI_WSTRB,
    output                                  DST_AXI_WVALID,
    output                                  DST_AXI_WLAST,
    input                                                   DST_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input[1:0]                                              DST_AXI_BRESP,
    input                                                   DST_AXI_BVALID,
    output                                  DST_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output[AW-1:0]                          DST_AXI_ARADDR,
    output                                  DST_AXI_ARVALID,
    output[2:0]                             DST_AXI_ARPROT,
    output                                  DST_AXI_ARLOCK,
    output[3:0]                             DST_AXI_ARID,
    output[2:0]                             DST_AXI_ARSIZE,
    output[7:0]                             DST_AXI_ARLEN,
    output[1:0]                             DST_AXI_ARBURST,
    output[3:0]                             DST_AXI_ARCACHE,
    output[3:0]                             DST_AXI_ARQOS,
    input                                                   DST_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input[DW-1:0]                                           DST_AXI_RDATA,
    input                                                   DST_AXI_RVALID,
    input[1:0]                                              DST_AXI_RRESP,
    input                                                   DST_AXI_RLAST,
    output                                  DST_AXI_RREADY
    //==========================================================================
);

data_mover # (.DW(512), .AW(64)) i_data_mover
(
    .clk             (clk),
    .resetn          (resetn),
    .src_address     (src_address),
    .dst_address     (64'h00_0000),
    .byte_count      (64'h10_0000),
    .burst_size      (4096),
    .start           (start & (src_address != 0)),
    .idle            (idle),

    .SRC_AXI_AWADDR  (SRC_AXI_AWADDR ),
    .SRC_AXI_AWVALID (SRC_AXI_AWVALID),
    .SRC_AXI_AWLEN   (SRC_AXI_AWLEN  ),
    .SRC_AXI_AWSIZE  (SRC_AXI_AWSIZE ),
    .SRC_AXI_AWID    (SRC_AXI_AWID   ),
    .SRC_AXI_AWBURST (SRC_AXI_AWBURST),
    .SRC_AXI_AWLOCK  (SRC_AXI_AWLOCK ),
    .SRC_AXI_AWCACHE (SRC_AXI_AWCACHE),
    .SRC_AXI_AWQOS   (SRC_AXI_AWQOS  ),
    .SRC_AXI_AWPROT  (SRC_AXI_AWPROT ),
    .SRC_AXI_AWREADY (SRC_AXI_AWREADY),

    .SRC_AXI_WDATA   (SRC_AXI_WDATA  ),
    .SRC_AXI_WSTRB   (SRC_AXI_WSTRB  ),
    .SRC_AXI_WVALID  (SRC_AXI_WVALID ),
    .SRC_AXI_WLAST   (SRC_AXI_WLAST  ),
    .SRC_AXI_WREADY  (SRC_AXI_WREADY ),

    .SRC_AXI_BRESP   (SRC_AXI_BRESP  ),
    .SRC_AXI_BVALID  (SRC_AXI_BVALID ),
    .SRC_AXI_BREADY  (SRC_AXI_BREADY ),

    .SRC_AXI_ARADDR  (SRC_AXI_ARADDR ),
    .SRC_AXI_ARVALID (SRC_AXI_ARVALID),
    .SRC_AXI_ARPROT  (SRC_AXI_ARPROT ),
    .SRC_AXI_ARLOCK  (SRC_AXI_ARLOCK ),
    .SRC_AXI_ARID    (SRC_AXI_ARID   ),
    .SRC_AXI_ARSIZE  (SRC_AXI_ARSIZE ),
    .SRC_AXI_ARLEN   (SRC_AXI_ARLEN  ),
    .SRC_AXI_ARBURST (SRC_AXI_ARBURST),
    .SRC_AXI_ARCACHE (SRC_AXI_ARCACHE),
    .SRC_AXI_ARQOS   (SRC_AXI_ARQOS  ),
    .SRC_AXI_ARREADY (SRC_AXI_ARREADY),
    .SRC_AXI_RDATA   (SRC_AXI_RDATA  ),

    .SRC_AXI_RVALID  (SRC_AXI_RVALID ),
    .SRC_AXI_RRESP   (SRC_AXI_RRESP  ),
    .SRC_AXI_RLAST   (SRC_AXI_RLAST  ),
    .SRC_AXI_RREADY  (SRC_AXI_RREADY ),

    .DST_AXI_AWADDR  (DST_AXI_AWADDR ),
    .DST_AXI_AWVALID (DST_AXI_AWVALID),
    .DST_AXI_AWLEN   (DST_AXI_AWLEN  ),
    .DST_AXI_AWSIZE  (DST_AXI_AWSIZE ),
    .DST_AXI_AWID    (DST_AXI_AWID   ),
    .DST_AXI_AWBURST (DST_AXI_AWBURST),
    .DST_AXI_AWLOCK  (DST_AXI_AWLOCK ),
    .DST_AXI_AWCACHE (DST_AXI_AWCACHE),
    .DST_AXI_AWQOS   (DST_AXI_AWQOS  ),
    .DST_AXI_AWPROT  (DST_AXI_AWPROT ),
    .DST_AXI_AWREADY (DST_AXI_AWREADY),

    .DST_AXI_WDATA   (DST_AXI_WDATA  ),
    .DST_AXI_WSTRB   (DST_AXI_WSTRB  ),
    .DST_AXI_WVALID  (DST_AXI_WVALID ),
    .DST_AXI_WLAST   (DST_AXI_WLAST  ),
    .DST_AXI_WREADY  (DST_AXI_WREADY ),

    .DST_AXI_BRESP   (DST_AXI_BRESP  ),
    .DST_AXI_BVALID  (DST_AXI_BVALID ),
    .DST_AXI_BREADY  (DST_AXI_BREADY ),

    .DST_AXI_ARADDR  (DST_AXI_ARADDR ),
    .DST_AXI_ARVALID (DST_AXI_ARVALID),
    .DST_AXI_ARPROT  (DST_AXI_ARPROT ),
    .DST_AXI_ARLOCK  (DST_AXI_ARLOCK ),
    .DST_AXI_ARID    (DST_AXI_ARID   ),
    .DST_AXI_ARSIZE  (DST_AXI_ARSIZE ), 
    .DST_AXI_ARLEN   (DST_AXI_ARLEN  ),
    .DST_AXI_ARBURST (DST_AXI_ARBURST),
    .DST_AXI_ARCACHE (DST_AXI_ARCACHE),
    .DST_AXI_ARQOS   (DST_AXI_ARQOS  ),
    .DST_AXI_ARREADY (DST_AXI_ARREADY),

    .DST_AXI_RDATA   (DST_AXI_RDATA  ),
    .DST_AXI_RVALID  (DST_AXI_RVALID ),
    .DST_AXI_RRESP   (DST_AXI_RRESP  ),
    .DST_AXI_RLAST   (DST_AXI_RLAST  ),
    .DST_AXI_RREADY  (DST_AXI_RREADY )

);



endmodule