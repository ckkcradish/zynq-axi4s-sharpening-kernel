module intensity_kernel(clk, rst_n, s_axis_tdata, s_axis_tvalid, s_axis_tuser, s_axis_tlast, s_axis_tready, m_axis_tdata, m_axis_tvalid, m_axis_tuser, m_axis_tlast, m_axis_tready, org_pixels);
    input wire clk;
    input wire rst_n;
    input wire [PXL_D_WIDTH*3-1:0] s_axis_tdata;
    input wire s_axis_tvalid;
    input wire s_axis_tuser;
    input wire s_axis_tlast;
    output wire s_axis_tready;
    output wire [PXL_D_WIDTH-1:0] m_axis_tdata;
    output wire m_axis_tvalid;
    output wire m_axis_tuser;
    output wire m_axis_tlast;
    input wire m_axis_tready;
	/*** Original Image Pixels ***/
	output wire [PXL_D_WIDTH*3-1:0] org_pixels;
    
parameter PXL_D_WIDTH = 8;
parameter VERT_SIZE = 720;

wire [PXL_D_WIDTH-1:0] pxl_r;
wire [PXL_D_WIDTH-1:0] pxl_g;
wire [PXL_D_WIDTH-1:0] pxl_b;
assign pxl_r = s_axis_tdata[PXL_D_WIDTH*3-1:PXL_D_WIDTH*2];
assign pxl_g = s_axis_tdata[PXL_D_WIDTH*2-1:PXL_D_WIDTH*1];
assign pxl_b = s_axis_tdata[PXL_D_WIDTH*1-1:PXL_D_WIDTH*0];

/*** 1st Pipeline Register ***/
reg [PXL_D_WIDTH-1:0] r0_pxl_r;
reg [PXL_D_WIDTH-1:0] r0_pxl_g;
reg [PXL_D_WIDTH-1:0] r0_pxl_b;
reg r0_s_axis_tvalid;
reg r0_s_axis_tuser;
reg r0_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r0_org_pixels;
/*** 2nd Pipeline Register ***/
reg [PXL_D_WIDTH*2-1:0] r1_pxl_r;
reg [PXL_D_WIDTH*2-1:0] r1_pxl_g;
reg [PXL_D_WIDTH*2-1:0] r1_pxl_b;
reg r1_s_axis_tvalid;
reg r1_s_axis_tuser;
reg r1_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r1_org_pixels;
/*** 3rd Pipeline Register ***/
reg [PXL_D_WIDTH*2-1:0] s2_pxl_rg;
reg [PXL_D_WIDTH*2-1:0] p2_pxl_b;
reg r2_s_axis_tvalid;
reg r2_s_axis_tuser;
reg r2_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r2_org_pixels;
/*** 4th Pipeline Register ***/
reg [PXL_D_WIDTH*2-1:0] s3_pxl_rgb;
reg r3_s_axis_tvalid;
reg r3_s_axis_tuser;
reg r3_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r3_org_pixels;
/*** 5th Pipeline Register ***/
reg [PXL_D_WIDTH-1:0] r4_pxl_intense;
reg r4_s_axis_tvalid;
reg r4_s_axis_tuser;
reg r4_s_axis_tlast;
reg [PXL_D_WIDTH*3-1:0] r4_org_pixels;
/*** Counting the vertial line ***/
reg [9:0] vert_cnt;

wire stall;
assign stall = ~m_axis_tready;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        /*** 1st Pipeline Register ***/
        r0_pxl_r <=  0;
        r0_pxl_g <=  0;
        r0_pxl_b <=  0;
        r0_s_axis_tvalid <=  0;
        r0_s_axis_tuser <=  0;
        r0_s_axis_tlast <=  0;
		r0_org_pixels <=  0;
        /*** 2nd Pipeline Register ***/
        r1_pxl_r <=  0;
        r1_pxl_g <=  0;
        r1_pxl_b <=  0;
        r1_s_axis_tvalid <=  0;
        r1_s_axis_tuser <=  0;
        r1_s_axis_tlast <=  0;
		r1_org_pixels <=  0;
        /*** 3rd Pipeline Register ***/
        s2_pxl_rg <=  0;
        p2_pxl_b  <=  0;
        r2_s_axis_tvalid <=  0;
        r2_s_axis_tuser <=  0;
        r2_s_axis_tlast <=  0;
		r2_org_pixels <=  0;
        /*** 4th Pipeline Register ***/
        s3_pxl_rgb <=  0;
        r3_s_axis_tvalid <=  0;
        r3_s_axis_tuser <=  0;
        r3_s_axis_tlast <=  0;
		r3_org_pixels <=  0;
        /*** 5th Pipeline Regsiter ***/
        r4_pxl_intense <=  0;
        r4_s_axis_tvalid <=  0;
        r4_s_axis_tuser <=  0;
        r4_s_axis_tlast <=  0;
		r4_org_pixels <=  0;
        /*** Counting the vertial line ***/
        vert_cnt <=  0;
    end else begin
        /*** 1st pipeline ***/
        r0_pxl_r <=  pxl_r;
        r0_pxl_g <=  pxl_g;
        r0_pxl_b <=  pxl_b;
        r0_s_axis_tvalid <=  s_axis_tvalid;
        r0_s_axis_tuser <=  s_axis_tuser;
        r0_s_axis_tlast <=  s_axis_tlast;
		r0_org_pixels <= s_axis_tdata;
        /*** 2nd pipeline ***/
        r1_pxl_r <=  r0_pxl_r * 8'd77;
        r1_pxl_g <=  r0_pxl_g * 8'd151;
        r1_pxl_b <=  r0_pxl_b * 8'd28;
        r1_s_axis_tvalid <=  r0_s_axis_tvalid;
        r1_s_axis_tuser <=  r0_s_axis_tuser;
        r1_s_axis_tlast <=  r0_s_axis_tlast;
		r1_org_pixels <=  r0_org_pixels;
        /*** 3rd pipeline ***/
        s2_pxl_rg <=  r1_pxl_r + r1_pxl_g;
        p2_pxl_b  <=  r1_pxl_b;
        r2_s_axis_tvalid <=  r1_s_axis_tvalid;
        r2_s_axis_tuser <=  r1_s_axis_tuser;
        r2_s_axis_tlast <=  r1_s_axis_tlast;
		r2_org_pixels <=  r1_org_pixels;
        /*** 4th pipeline ***/
        s3_pxl_rgb <=  s2_pxl_rg + p2_pxl_b;
        r3_s_axis_tvalid <=  r2_s_axis_tvalid;
        r3_s_axis_tuser <=  r2_s_axis_tuser;
        r3_s_axis_tlast <=  r2_s_axis_tlast;
		r3_org_pixels <=  r2_org_pixels;
        /*** 5th pipeline ***/
        r4_pxl_intense <=  s3_pxl_rgb >> 8;
        r4_s_axis_tvalid <=  r3_s_axis_tvalid;
        r4_s_axis_tuser <=  r3_s_axis_tuser;
        r4_s_axis_tlast <=  r3_s_axis_tlast;
        vert_cnt <=  (r4_s_axis_tvalid & r4_s_axis_tlast) ? vert_cnt + 1 : vert_cnt;
		r4_org_pixels <=  r3_org_pixels;
    end
end

assign s_axis_tready = m_axis_tready;
assign m_axis_tdata = r4_pxl_intense;
assign m_axis_tvalid = r4_s_axis_tvalid;
assign m_axis_tuser = r4_s_axis_tuser;
assign m_axis_tlast = r4_s_axis_tlast;
assign org_pixels = r4_org_pixels;

endmodule
