module sharpening_kernel(
    input wire clk,
    input wire rst_n,
    // Control Signals
    input wire s_axis_tvalid,
    input wire s_axis_tuser,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    // Data Inputs (Sharpening uses 5 pixels: Cross)
    input wire [PXL_D_WIDTH-1:0] din0, // Center (do_11)
    input wire [PXL_D_WIDTH-1:0] din1, // Up     (do_01)
    input wire [PXL_D_WIDTH-1:0] din2, // Down   (do_21)
    input wire [PXL_D_WIDTH-1:0] din3, // Left   (do_10)
    input wire [PXL_D_WIDTH-1:0] din4, // Right  (do_12)
    // Master Output
    output wire [PXL_D_WIDTH*3-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tuser,
    output wire m_axis_tlast,
    input wire m_axis_tready,
    // Original RGB Input
    input wire [PXL_D_WIDTH*3-1:0] in_org_pixels,
    input wire hwsw_sel
);

parameter PXL_D_WIDTH = 8;

// ==========================================
// Pipeline Stage 1: Calculate Detail (Laplacian)
// Formula: 4*Center - (Up+Down+Left+Right)
// ==========================================
reg signed [PXL_D_WIDTH+2:0] detail_val; // 11-bit signed to prevent overflow
reg r0_s_axis_tvalid;
reg r0_s_axis_tuser;
reg r0_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r0_org_pixels;

// ==========================================
// Pipeline Stage 2: Add to RGB & Clamp
// ==========================================
reg [PXL_D_WIDTH-1:0] sharp_r, sharp_g, sharp_b;
reg r1_s_axis_tvalid;
reg r1_s_axis_tuser;
reg r1_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r1_org_pixels;

wire stall;
assign stall = ~m_axis_tready;

// Use 10-bit signed for temporary color sum to handle negative results or overflow
reg signed [11:0] temp_r, temp_g, temp_b; 

always @(*) begin
        // Calculate R + Detail
        temp_r = $signed({1'b0, r0_org_pixels[23:16]}) + detail_val;
        // Calculate G + Detail
        temp_g = $signed({1'b0, r0_org_pixels[15:8]}) + detail_val;
        // Calculate B + Detail
        temp_b = $signed({1'b0, r0_org_pixels[7:0]}) + detail_val;
end
    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Stage 1
        detail_val       <= '0;
        r0_s_axis_tvalid <= 1'b0;
        r0_s_axis_tuser  <= 1'b0;
        r0_s_axis_tlast  <= 1'b0;
        r0_org_pixels    <= '0;

        // Stage 2
        sharp_r          <= '0;
        sharp_g          <= '0;
        sharp_b          <= '0;
        r1_s_axis_tvalid <= 1'b0;
        r1_s_axis_tuser  <= 1'b0;
        r1_s_axis_tlast  <= 1'b0;
        r1_org_pixels    <= '0;
    end
        
    else if (!stall) begin
        // --- Stage 1: Calculate Laplacian Detail ---
        // Convert inputs to signed for calculation
        // detail = (4 * Center) - (Up + Down + Left + Right)
        detail_val <=  ($signed({1'b0, din0}) * 4) - 
                         ($signed({1'b0, din1}) + $signed({1'b0, din2}) + 
                          $signed({1'b0, din3}) + $signed({1'b0, din4}));

        r0_s_axis_tvalid <=  s_axis_tvalid;
        r0_s_axis_tuser  <=  s_axis_tuser;
        r0_s_axis_tlast  <=  s_axis_tlast;
        r0_org_pixels    <=  in_org_pixels;

        // --- Stage 2: Add Detail to Original RGB & Clamp --    
        // Clamp R
        if (temp_r[11]) sharp_r <=  8'd0;       // Negative (Sign bit 1)
        else if (temp_r > 255) sharp_r <=  8'd255; // Overflow
        else sharp_r <=  temp_r[7:0];

        // Clamp G
        if (temp_g[11]) sharp_g <=  8'd0;
        else if (temp_g > 255) sharp_g <=  8'd255;
        else sharp_g <=  temp_g[7:0];

        // Clamp B
        if (temp_b[11]) sharp_b <=  8'd0;
        else if (temp_b > 255) sharp_b <=  8'd255;
        else sharp_b <=  temp_b[7:0];

        r1_s_axis_tvalid <=  r0_s_axis_tvalid;
        r1_s_axis_tuser  <=  r0_s_axis_tuser;
        r1_s_axis_tlast  <=  r0_s_axis_tlast;
        r1_org_pixels    <=  r0_org_pixels;
    end
end

assign s_axis_tready = m_axis_tready;

// Output: Select between Sharpened Image or Original Image
assign m_axis_tdata  = (hwsw_sel) ? {sharp_r, sharp_g, sharp_b} : r1_org_pixels;
assign m_axis_tvalid = r1_s_axis_tvalid;
assign m_axis_tuser  = r1_s_axis_tuser;
assign m_axis_tlast  = r1_s_axis_tlast;

endmodule
