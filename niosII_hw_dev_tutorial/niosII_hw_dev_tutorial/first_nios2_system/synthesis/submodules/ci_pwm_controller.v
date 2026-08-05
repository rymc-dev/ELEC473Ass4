// -------------------------------
// Module      : ci_pwm_controller
// Description : Nios II "Extended" (variable-latency) custom instruction.
//               Takes a brightness level 0-9 on dataa, converts it to an
//               8-bit PWM duty value, and issues a single Avalon-MM write
//               to the pwm peripheral's duty register. Reports done once
//               the write has been accepted (waitrequest deasserted).
//
// Author      : Ryan McKee
//
// Custom Instruction Slave Interface (connects to cpu's
// "Custom Instruction Master" port - this is an "Extended" type CI
// because the Avalon write can take a variable number of cycles
// depending on avm_waitrequest, so both start and done are required):
//    ncs_clk     - shared with system clock
//    ncs_clk_en  - assert every cycle this instruction should progress;
//                  deasserted if the CPU stalls for an unrelated reason
//    ncs_reset   - CPU master reset
//    ncs_start   - pulses for 1 cycle when the CPU issues this
//                  instruction; dataa is valid on this same cycle
//    ncs_dataa   - [3:0] used as brightness level 0-9 (values 10-15
//                  saturate to full brightness rather than wrapping)
//    ncs_result  - duty value written, zero-extended (informational,
//                  can be discarded by software if not needed)
//    ncs_done    - pulses for 1 cycle when the write has completed
//
// Avalon-MM Master Interface (connects to pwm's avalon_slave_0, wired
// in the System Contents connections matrix like any other master):
//    avm_address    - tied to PWM_BASE_ADDR, never changes
//    avm_write      - asserted while the write is outstanding
//    avm_read       - unused, permanently 0 (this master never reads)
//    avm_writedata  - duty value in bits [7:0], zero elsewhere
//    avm_readdata   - unused (this master never reads)
//    avm_waitrequest - deasserting this is what allows the write to
//                       complete; the FSM holds avm_write high until
//                       the slave accepts it
//
// Notes:
//    - PWM_BASE_ADDR must match the base address Qsys assigns to the
//      pwm component's avalon_slave_0 (check system.h -> PWM_0_BASE
//      after regenerating, update the parameter here if it differs).
//    - Level-to-duty mapping spans 0 to PWM_RESOLUTION(254) in 10 even
//      steps (~28 per level), matching pwm.v's default PWM_RESOLUTION.
//      If you change PWM_RESOLUTION in pwm.v, update this table too.
module ci_pwm_controller #(
    parameter [31:0] PWM_BASE_ADDR = 32'h0008_8000
)(
    // Standalone clock/reset ports, NOT used anywhere in the logic below.
    // These exist purely so Platform Designer's Component Editor
    // auto-detects a genuine Clock Input / Reset Input interface (named
    // "clock" / "reset" once analyzed) for avalon_master_0's Associated
    // Clock / Associated Reset dropdowns to point at - a Custom
    // Instruction Slave's internal clk/reset don't count as a valid
    // clock source for that association. At the system level in
    // Qsys/Platform Designer, wire both of these to clocks_sys... same
    // as every other component; it's the same physical clock as ncs_clk,
    // just exposed a second way so the tool's interface bookkeeping is
    // satisfied.
    input              clk,
    input              reset,

    // Nios II Custom Instruction Slave Interface
    input              ncs_clk,
    input              ncs_clk_en,
    input              ncs_reset,
    input              ncs_start,
    input      [31:0]  ncs_dataa,
    output reg [31:0]  ncs_result,
    output reg         ncs_done,
    // Avalon-MM Master Interface
    output reg [31:0]  avm_address,
    output reg         avm_write,
    output reg         avm_read,
    output reg [31:0]  avm_writedata,
    input      [31:0]  avm_readdata,
    input              avm_waitrequest
);

    // Brightness level (0-9) -> 8-bit PWM duty value, spanning 0..254
    // in ~28-count steps. Levels 10-15 clamp to full brightness (254)
    // rather than producing an out-of-range or wrapped value.
    function [7:0] level_to_duty;
        input [3:0] level;
        begin
            case (level)
                4'd0: level_to_duty = 8'd0;
                4'd1: level_to_duty = 8'd28;
                4'd2: level_to_duty = 8'd56;
                4'd3: level_to_duty = 8'd85;
                4'd4: level_to_duty = 8'd113;
                4'd5: level_to_duty = 8'd141;
                4'd6: level_to_duty = 8'd170;
                4'd7: level_to_duty = 8'd198;
                4'd8: level_to_duty = 8'd226;
                default: level_to_duty = 8'd254; // level 9, and 10-15 clamp here too
            endcase
        end
    endfunction

    localparam IDLE  = 1'b0,
               WRITE = 1'b1;

    reg state;

    always @(posedge ncs_clk or posedge ncs_reset) begin
        if (ncs_reset) begin
            state         <= IDLE;
            ncs_done      <= 1'b0;
            ncs_result    <= 32'd0;
            avm_write     <= 1'b0;
            avm_read      <= 1'b0;          // this master never reads
            avm_address   <= PWM_BASE_ADDR; // constant, set once
            avm_writedata <= 32'd0;
        end else if (ncs_clk_en) begin
            case (state)
                IDLE: begin
                    ncs_done <= 1'b0;
                    if (ncs_start) begin
                        avm_writedata <= {24'd0, level_to_duty(ncs_dataa[3:0])};
                        avm_write     <= 1'b1;
                        state         <= WRITE;
                    end
                end

                WRITE: begin
                    if (!avm_waitrequest) begin
                        // Slave accepted the write this cycle
                        avm_write  <= 1'b0;
                        ncs_result <= {24'd0, level_to_duty(ncs_dataa[3:0])};
                        ncs_done   <= 1'b1;
                        state      <= IDLE;
                    end
                    // else: hold avm_write/avm_writedata steady and wait
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule