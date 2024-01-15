/*
    Summary:    Generic video graphics array interface
*/

import com::*;

module vga #(
        parameter int unsigned H_SIZE = 800,    // Screen width (pixels)
        parameter int unsigned V_SIZE = 600,    // Screen height (pixels)

        parameter int unsigned H_FP = 56,       // Horizontal front porch (pixels)
        parameter int unsigned H_SYNC = 120,    // Horizontal synchronization (pixels)
        parameter int unsigned H_BP = 64,       // Horizontal bock porch (pixels)

        parameter int unsigned V_FP = 37,       // Vertical front porch (lines)
        parameter int unsigned V_SYNC = 6,      // Vertical synchronization (lines)
        parameter int unsigned V_BP = 23        // Vertical back porch (lines)
)(
        input pixelclk, rst,
        input color color_in,
        output color color_out,

        // Next pixel's coordinates
        output [$clog2(H_SIZE) - 1 : 0] pix_x,
        output [$clog2(V_SIZE) - 1 : 0] pix_y,

        // VGA synchronization output
        output vga_vsync,
        output vga_hsync
    );

    localparam int unsigned H_SIZE_FULL = H_SIZE + H_FP + H_SYNC + H_BP;  // Full line length
    localparam int unsigned V_SIZE_FULL = V_SIZE + V_FP + V_SYNC + V_BP;  // Full frame height
    
    reg [$clog2(H_SIZE_FULL) - 1 : 0] cursor_x;
    reg [$clog2(V_SIZE_FULL) - 1 : 0] cursor_y;

    always @(posedge pixelclk, posedge rst) begin
        if (rst) begin
            cursor_x <= '0;
            cursor_y <= '0;
        end else begin
            if (cursor_x < H_SIZE_FULL) begin // Horizontal counter
                cursor_x ++;
            end else begin
                cursor_x = '0;

                if (cursor_y < V_SIZE_FULL) begin // Vertical counter
                    cursor_y++;
                end else begin
                    cursor_y = '0;
                end
            end

            if ((cursor_x < H_SIZE) && (cursor_y < V_SIZE)) begin // Check if cursor is visible
                color_out = color_in;

                // Update output coords
                pix_x = cursor_x + 1;
                pix_y = cursor_y + 1;
            end else begin
                color_out = '0;
                pix_x = '0;
                pix_y = '0;
            end

            if ((cursor_x > (H_SIZE + H_FP)) && (cursor_x < (H_SIZE + H_FP + H_SYNC))) begin // HSYNC
                vga_hsync = 1;
            end else begin
                vga_hsync = 0;
            end

            if ((cursor_y > (H_SIZE + V_FP)) && (cursor_y < (H_SIZE + V_FP + V_SYNC))) begin // VSYNC
                vga_vsync = 1;
            end else begin
                vga_vsync = 0;
            end
        end
    end
endmodule
