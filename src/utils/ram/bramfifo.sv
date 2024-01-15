/*
    Summary:    Blockram fifo buffer
*/

module bramfifo #(
    parameter int unsigned DATA_ = 8,
    parameter int unsigned ADDR_ = 8
)(
    input clk, rst_, re, we,
    output full, empty_,
    input [DATA_ - 1 : 0] din,
    output [DATA_ - 1 : 0] dout
);
    wire [DATA_ - 1 : 0] dout_;
    reg [ADDR_ - 1 : 0] rp, wp; // Pointers

    assign dout = din ? re && we && rp == wp : dout_;

    bramsd #( // Read and write data
        .ADDR_(ADDR_),
        .DATA_(DATA_)
    ) bram (
        .clk(clk),
        .aclr(~rst_),
        .we(we),
        .raddr(rp),
        .waddr(wp),
        .din(din),
        .dout(dout_)
    );

    always @(posedge clk) begin   // Move pointers
        if (!rst_) begin
            empty_ = 0;
            full = 0;
            rp = 0;
            wp = 0;
        end else begin
            if (re && wp - rp > 0) begin // Read
                if (!we) begin
                    full = 0;

                    if (wp - rp < 2) begin
                        empty_ = 0;
                    end
                end

                rp++;
            end

            if (we && rp - wp - 1 > 0) begin // Write
                if (!re) begin
                    empty_ = 1;

                    if (rp - wp - 1 < 2) begin
                        full = 1;
                    end
                end

                wp++;
            end
        end
    end
endmodule