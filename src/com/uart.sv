/*
    Summary:    Uart interface
*/

import com::*;

module uart #(
    parameter int unsigned CLK = 50000000,
    parameter int unsigned BAUDRATE = 115200,
    parameter int unsigned BUFFER_ = 8,
    parameter int unsigned START_ = 1,
    parameter int unsigned DATA_ = 8,
    parameter int unsigned STOP_ = 1,
    parameter parity PARITY = NONE
)(
    input clk, rst_, re, we,
    input rx,
    output tx,
    input [DATA_ - 1 : 0] din,
    output [DATA_ - 1 : 0] dout, test, // REMOVE TEST
    output rxavail, txavail
);
    localparam int unsigned BIT_ = CLK / BAUDRATE;
    localparam int unsigned PARITY_ = 0 ? PARITY == NONE : 1;
    localparam int unsigned MSG_ = START_ + DATA_ + PARITY_ + STOP_;

    // ==== RX ===========================================================

    reg [$clog2(BIT_) - 1 : 0] rxticks;
    reg [$clog2(MSG_) - 1 : 0] rxbits;
    reg [START_ + DATA_ - 1 : START_] rxdata;
    wire rxena, rxbufwe, rxbufempty_;

    assign rxavail = rxbufempty_;

    bramfifo #(
        .DATA_(DATA_),
        .ADDR_(BUFFER_)
    ) rxbuf (
        .clk(clk),
        .rst_(rst_),
        .re(re),
        .we(rxbufwe),
        .empty_(rxbufempty_),
        .din(rxdata),
        .dout(dout)
    );

    always @(posedge clk) begin
        if (!rst_) begin
            rxticks = 0;
            rxbits = 0;
            rxena = 0;
            rxbufwe = 0;
        end else begin
            if (!rxena) begin // Idle
                rxticks = BIT_ / 2;
                rxbits = 0;
                rxbufwe = 0;

                if (!rx) begin
                    rxena = 1;
                end
            end else begin
                if (rxticks < BIT_ - 1) begin // Tick counter
                    rxticks++;
                end else begin
                    rxticks = 0;

                    if (rxbits < START_) begin // Start bit check
                        if (rx) begin
                            rxena = 0;
                        end
                    end else if (rxbits < START_ + DATA_) begin // Data bits
                        rxdata[rxbits] = rx;
                    end else if (rxbits < START_ + DATA_ + PARITY_ && PARITY != NONE) begin // Parity check
                        case (PARITY)
                            EVEN: begin
                                if (^{rx, rxdata}) begin
                                    rxena = 0;
                                end
                            end ODD: begin
                                if (~^{rx, rxdata}) begin
                                    rxena = 0;
                                end
                            end MARK: begin
                                if (!rx) begin
                                    rxena = 0;
                                end
                            end SPACE: begin
                                if (rx) begin
                                    rxena = 0;
                                end
                            end
                        endcase
                    end else begin // Stop bits check
                        if (!rx) begin
                            rxena = 0;
                        end else if (!(rxbits < MSG_ - 1)) begin
                            rxena = 0;
                            rxbufwe = 1;
                        end
                    end

                    if (rxbits < MSG_ - 1) begin // Bit counter
                        rxbits++;
                    end
                end
            end
        end
    end

    // ==== TX ===========================================================

    reg [$clog2(BIT_) - 1 : 0] txticks;
    reg [$clog2(MSG_) - 1 : 0] txbits;
    reg [START_ + DATA_ - 1 : START_] txdata;
    reg txena, txbufre, txbufempty_, txbuffull;

    assign txavail = ~txbuffull;

    bramfifo #(
        .DATA_(DATA_),
        .ADDR_(BUFFER_)
    ) txbuf (
        .clk(clk),
        .rst_(rst_),
        .re(txbufre),
        .we(we),
        .empty_(txbufempty_),
        .full(txbuffull),
        .din(din),
        .dout(txdata)
    );

    assign test = txdata; // DELETE

    always @(posedge clk) begin
        if (!rst_) begin
            tx = 1;
            txticks = 0;
            txbits = 0;
            txena = 0;
            txbufre = 0;
        end else begin
            if (!txena) begin // Idle
                txticks = 0;
                txbits = 0;
                txbufre = 0;

                if (txbufempty_) begin
                    txena = 1;
                end
            end else begin
                if (txticks < BIT_ - 1) begin // Tick counter
                    txticks++;
                end else begin
                    txticks = 0;

                    if (txbits < START_) begin // Start bit check
                        tx = 0;
                    end else if (txbits < START_ + DATA_) begin // Data bits
                        tx = txdata[txbits];
                    end else if (txbits < START_ + DATA_ + PARITY_ && PARITY != NONE) begin // Parity check
                        case (PARITY)
                            EVEN: begin
                                tx = ^txdata;
                            end ODD: begin
                                tx = ~^txdata;
                            end MARK: begin
                                tx = 1;
                            end SPACE: begin
                                tx = 0;
                            end
                        endcase
                    end else begin // Stop bits check
                        tx = 1;
                    end

                    if (txbits < MSG_ - 1) begin // Bit counter
                        txbits++;
                    end else begin
                        txena = 0;
                        txbufre = 1;
                    end
                end
            end
        end
    end
endmodule
