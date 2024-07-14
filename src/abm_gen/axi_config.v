//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 14-Jun-24  DWW     1  Initial creation
// 13-Jun-24  DWW     2  Updated to support loading ABM via DMA from host RAM
//====================================================================================

/*
    Configuration and status
*/


module axi_config
(
    input clk, resetn,

    // These are the ABM data patterns for each channel
    output reg[31:0] pattern0, pattern1,

    // Strobe this when a pattern should be sent to the RDMX target
    output reg gen_pattern_start,

    // Strobe them when an ABM should be DMA'd and sent to the RDMX target
    output reg dma_start0, dma_start1,

    // These are the addresses in host RAM where we can DMA ABM data from
    output reg[63:0] host_addr0, host_addr1,

    // These tell us is the ABM-generator modules are idle
    input   gen_pattern_idle0, gen_pattern_idle1,
    input           dma_idle0,         dma_idle1,

    // These report PCS alignment from the CMACs
    input   rx_aligned0, rx_aligned1,

    //================== This is an AXI4-Lite slave interface ==================
        
    // "Specify write address"              -- Master --    -- Slave --
    input[31:0]                             S_AXI_AWADDR,   
    input                                   S_AXI_AWVALID,  
    output                                                  S_AXI_AWREADY,
    input[2:0]                              S_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    input[31:0]                             S_AXI_WDATA,      
    input                                   S_AXI_WVALID,
    input[3:0]                              S_AXI_WSTRB,
    output                                                  S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output[1:0]                                             S_AXI_BRESP,
    output                                                  S_AXI_BVALID,
    input                                   S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input[31:0]                             S_AXI_ARADDR,     
    input                                   S_AXI_ARVALID,
    input[2:0]                              S_AXI_ARPROT,     
    output                                                  S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output[31:0]                                            S_AXI_RDATA,
    output                                                  S_AXI_RVALID,
    output[1:0]                                             S_AXI_RRESP,
    input                                   S_AXI_RREADY
    //==========================================================================
);  


//=========================  AXI Register Map  =============================
localparam REG_PATTERN0      = 0;
localparam REG_PATTERN1      = 1;
localparam REG_START_PATTERN = 2;
localparam REG_START_DMA     = 3;
localparam REG_RUN_STATUS    = 4;
localparam REG_QSFP_STATUS   = 5;
localparam REG_DMA_ADDR0H    = 6;
localparam REG_DMA_ADDR0L    = 7;
localparam REG_DMA_ADDR1H    = 8;
localparam REG_DMA_ADDR1L    = 9;
//==========================================================================

// This is the default host RAM address we'll DMA ABM data from
localparam[63:0] DEFAULT_DMA_ADDR = 64'h1_0000_0000;

//==========================================================================
// We'll communicate with the AXI4-Lite Slave core with these signals.
//==========================================================================
// AXI Slave Handler Interface for write requests
wire[31:0]  ashi_windx;     // Input   Write register-index
wire[31:0]  ashi_waddr;     // Input:  Write-address
wire[31:0]  ashi_wdata;     // Input:  Write-data
wire        ashi_write;     // Input:  1 = Handle a write request
reg[1:0]    ashi_wresp;     // Output: Write-response (OKAY, DECERR, SLVERR)
wire        ashi_widle;     // Output: 1 = Write state machine is idle

// AXI Slave Handler Interface for read requests
wire[31:0]  ashi_rindx;     // Input   Read register-index
wire[31:0]  ashi_raddr;     // Input:  Read-address
wire        ashi_read;      // Input:  1 = Handle a read request
reg[31:0]   ashi_rdata;     // Output: Read data
reg[1:0]    ashi_rresp;     // Output: Read-response (OKAY, DECERR, SLVERR);
wire        ashi_ridle;     // Output: 1 = Read state machine is idle
//==========================================================================

// The state of the state-machines that handle AXI4-Lite read and AXI4-Lite write
reg ashi_write_state, ashi_read_state;

// The AXI4 slave state machines are idle when in state 0 and their "start" signals are low
assign ashi_widle = (ashi_write == 0) && (ashi_write_state == 0);
assign ashi_ridle = (ashi_read  == 0) && (ashi_read_state  == 0);
   
// These are the valid values for ashi_rresp and ashi_wresp
localparam OKAY   = 0;
localparam SLVERR = 2;
localparam DECERR = 3;

// An AXI slave is gauranteed a minimum of 128 bytes of address space
// (128 bytes is 32 32-bit registers)
localparam ADDR_MASK = 7'h7F;

// Are we busy sending a generated ABM?
wire[1:0] gen_busy = {~gen_pattern_idle1, ~gen_pattern_idle0};

// Are we busy sending a DMA'd ABM?
wire[1:0] dma_busy = {~dma_idle1, ~dma_idle0};

// We're idle when all of the idle inputs are high
wire abm_send_idle = (gen_pattern_idle0 & gen_pattern_idle1 & dma_idle0 & dma_idle1);

// Synchronize the "rx_aligned" signals into "sync_aligned" signals
wire[1:0] sync_aligned;
cdc_single i_cdc0 (rx_aligned0, clk, sync_aligned[0]);
cdc_single i_cdc1 (rx_aligned1, clk, sync_aligned[1]);


//==========================================================================
// This state machine handles AXI4-Lite write requests
//
// Drives:
//==========================================================================
always @(posedge clk) begin

    // These strobe high for one cycle at a time
    gen_pattern_start <= 0;
    dma_start0        <= 0;
    dma_start1        <= 0;

    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_write_state  <= 0;
        pattern0          <= 0;
        pattern1          <= 0;
        host_addr0        <= DEFAULT_DMA_ADDR;
        host_addr1        <= DEFAULT_DMA_ADDR;

    // If we're not in reset, and a write-request has occured...        
    end else case (ashi_write_state)
        
        0:  if (ashi_write) begin
       
                // Assume for the moment that the result will be OKAY
                ashi_wresp <= OKAY;              
            
                // Examine the register index and...
                case (ashi_windx)
               
                    REG_PATTERN0:   pattern0          <= ashi_wdata;
                    REG_PATTERN1:   pattern1          <= ashi_wdata;
                    REG_DMA_ADDR0H: host_addr0[63:32] <= ashi_wdata;
                    REG_DMA_ADDR0L: host_addr0[31:00] <= ashi_wdata;
                    REG_DMA_ADDR1H: host_addr1[63:32] <= ashi_wdata;
                    REG_DMA_ADDR1L: host_addr1[31:00] <= ashi_wdata;


                    REG_START_PATTERN:
                        if (abm_send_idle) begin
                            if (ashi_wdata) gen_pattern_start <= 1;
                        end

                    REG_START_DMA:
                        if (abm_send_idle) begin
                            dma_start0 <= ashi_wdata[0];
                            dma_start1 <= ashi_wdata[1];
                        end

                    // Writes to any other register are a decode-error
                    default: ashi_wresp <= DECERR;
                endcase
            end

        // Dummy state, doesn't do anything
        1: ashi_write_state <= 0;

    endcase
end
//==========================================================================





//==========================================================================
// World's simplest state machine for handling AXI4-Lite read requests
//==========================================================================
always @(posedge clk) begin
    // If we're in reset, initialize important registers
    if (resetn == 0) begin
        ashi_read_state <= 0;
    
    // If we're not in reset, and a read-request has occured...        
    end else if (ashi_read) begin
   
        // Assume for the moment that the result will be OKAY
        ashi_rresp <= OKAY;              
        
        // Examine the register index and...
        case (ashi_rindx)
            
            // Allow a read from any valid register                
            REG_PATTERN0:      ashi_rdata <= pattern0;
            REG_PATTERN1:      ashi_rdata <= pattern1;
            REG_START_PATTERN: ashi_rdata <= gen_busy;
            REG_START_DMA:     ashi_rdata <= dma_busy;
            REG_RUN_STATUS:    ashi_rdata <= {gen_busy, dma_busy};
            REG_QSFP_STATUS:   ashi_rdata <= sync_aligned;
            REG_DMA_ADDR0H:    ashi_rdata <= host_addr0[63:32];
            REG_DMA_ADDR0L:    ashi_rdata <= host_addr0[31:00];
            REG_DMA_ADDR1H:    ashi_rdata <= host_addr1[63:32];
            REG_DMA_ADDR1L:    ashi_rdata <= host_addr1[31:00];

            // Reads of any other register are a decode-error
            default: ashi_rresp <= DECERR;
        endcase
    end
end
//==========================================================================



//==========================================================================
// This connects us to an AXI4-Lite slave core
//==========================================================================
axi4_lite_slave#(ADDR_MASK) axil_slave
(
    .clk            (clk),
    .resetn         (resetn),
    
    // AXI AW channel
    .AXI_AWADDR     (S_AXI_AWADDR),
    .AXI_AWVALID    (S_AXI_AWVALID),   
    .AXI_AWREADY    (S_AXI_AWREADY),
    
    // AXI W channel
    .AXI_WDATA      (S_AXI_WDATA),
    .AXI_WVALID     (S_AXI_WVALID),
    .AXI_WSTRB      (S_AXI_WSTRB),
    .AXI_WREADY     (S_AXI_WREADY),

    // AXI B channel
    .AXI_BRESP      (S_AXI_BRESP),
    .AXI_BVALID     (S_AXI_BVALID),
    .AXI_BREADY     (S_AXI_BREADY),

    // AXI AR channel
    .AXI_ARADDR     (S_AXI_ARADDR), 
    .AXI_ARVALID    (S_AXI_ARVALID),
    .AXI_ARREADY    (S_AXI_ARREADY),

    // AXI R channel
    .AXI_RDATA      (S_AXI_RDATA),
    .AXI_RVALID     (S_AXI_RVALID),
    .AXI_RRESP      (S_AXI_RRESP),
    .AXI_RREADY     (S_AXI_RREADY),

    // ASHI write-request registers
    .ASHI_WADDR     (ashi_waddr),
    .ASHI_WINDX     (ashi_windx),
    .ASHI_WDATA     (ashi_wdata),
    .ASHI_WRITE     (ashi_write),
    .ASHI_WRESP     (ashi_wresp),
    .ASHI_WIDLE     (ashi_widle),

    // ASHI read registers
    .ASHI_RADDR     (ashi_raddr),
    .ASHI_RINDX     (ashi_rindx),
    .ASHI_RDATA     (ashi_rdata),
    .ASHI_READ      (ashi_read ),
    .ASHI_RRESP     (ashi_rresp),
    .ASHI_RIDLE     (ashi_ridle)
);
//==========================================================================



endmodule
