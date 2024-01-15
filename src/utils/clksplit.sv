/*
    Summary:    Generic clock split generator
*/

module clksplit #(
    parameter int unsigned T = 'd50000000
)(
    input wire clk, rst_, ena,
    output reg cke
);
    wire [$clog2(T) - 1 : 0] count;

    counter #(
        .T(T)
    ) ctr (
        .clk(clk),
        .rst_(rst_),
        .ena(ena),
        .count(count)
    );

    assign cke = 1 ? count <= (T >> 1) + 1 && rst_ && ena : 0;
endmodule
