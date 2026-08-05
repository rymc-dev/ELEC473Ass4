module count_leading_ones (
    // Nios II custom instruction slave interface
    // "ncs_" prefix lets Platform Designer auto-recognize these as the
    // Nios II custom instruction slave interface (clk, clk_en, reset,
    // dataa, result) instead of guessing a generic Avalon-MM slave.
    ncs_clk,
    ncs_clk_en,
    ncs_reset,
    ncs_dataa,
    ncs_result
);

input         ncs_clk;
input         ncs_clk_en;
input         ncs_reset;
input  [31:0] ncs_dataa;
output [31:0] ncs_result;

// Priority tree, halving each stage — pure combinational.
// Counts leading '1' bits from the MSB of ncs_dataa.

wire msb16_all1 = (ncs_dataa[31:16] == 16'hFFFF);
wire [15:0] next16 = msb16_all1 ? ncs_dataa[15:0] : ncs_dataa[31:16];

wire msb8_all1 = (next16[15:8] == 8'hFF);
wire [7:0] next8 = msb8_all1 ? next16[7:0] : next16[15:8];

wire msb4_all1 = (next8[7:4] == 4'hF);
wire [3:0] next4 = msb4_all1 ? next8[3:0] : next8[7:4];

wire msb2_all1 = (next4[3:2] == 2'b11);
wire [1:0] next2 = msb2_all1 ? next4[1:0] : next4[3:2];

wire msb1_all1 = next2[1];
wire bit0 = msb1_all1 ? next2[0] : 1'b0;

assign ncs_result = (msb16_all1 ? 16 : 0)
                   + (msb8_all1  ? 8  : 0)
                   + (msb4_all1  ? 4  : 0)
                   + (msb2_all1  ? 2  : 0)
                   + (msb1_all1  ? 1  : 0)
                   + (msb1_all1 & bit0 ? 1 : 0);

endmodule