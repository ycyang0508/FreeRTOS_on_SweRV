
module ahb_sif (
                  input logic [63:0] HWDATA,
                  input logic HCLK,
                  input logic HSEL,
                  input logic [3:0] HPROT,
                  input logic HWRITE,
                  input logic [1:0] HTRANS,
                  input logic [2:0] HSIZE,
                  input logic HREADY,
                  input logic HRESETn,
                  input logic [31:0] HADDR,
                  input logic [2:0] HBURST,

                  output logic HREADYOUT,
                  output logic HRESP,
                  output logic [63:0] HRDATA

);

import ahb3lite_pkg::*;

localparam MEM_SIZE_DW = 128*1024*8;
localparam MAILBOX_ADDR = 32'hD0580000;
localparam TIMER_ADDR   = 32'hD0590000;

logic Last_HSEL;
logic NextLast_HSEL;
logic Last_HWRITE;
logic [1:0] Last_HTRANS;
logic [1:0] NextLast_HTRANS;
logic [31:0] Last_HADDR;
logic [63:0] Next_HRDATA;
logic [63:0] WriteReadData;
logic [63:0] WriteMask;

//bit [7:0] mem [0:MEM_SIZE_DW-1];

typedef struct packed
{
    int          cmdID;
    logic [63:0] HWDATA ;    
    logic        HSEL   ; 
    logic [3:0]  HPROT  ;
    logic        HWRITE ;
    logic [1:0]  HTRANS ;
    logic [2:0]  HSIZE  ;  
    logic [31:0] HADDR  ;
    logic [2:0]  HBURST ;  

} AHBCmd_t;

typedef struct packed
{
    int cmdID;
    logic HREADYOUT;
    logic HRESP;
    logic [63:0] HRDATA;
    logic mailbox_write;
    logic [7:0] mailbox_data;

    logic timer_write;
    logic [7:0] timer_data;

} AHBResult_t;

logic mailbox_write = 0;
AHBCmd_t ahbCmd;
int cmdID_reg = 0;
AHBResult_t ahbRlt;
int wrByteSel;
//write
function automatic AHBResult_t genWriteData(input AHBCmd_t ahbCmdIn);    
    int addr_64bit;
    
    logic[27:0] write_addr;

    write_addr = ahbCmd.HADDR[27:0];

    genWriteData = 'd0;
    if ((write_addr == MAILBOX_ADDR[27:0]) & (ahbCmd.HSIZE == HSIZE_B8))
    begin
        genWriteData.mailbox_write = 'd1;
        genWriteData.mailbox_data  = ahbCmd.HWDATA[7:0];
        return genWriteData;
    end
    else if (write_addr == TIMER_ADDR[27:0] & (ahbCmd.HSIZE == HSIZE_B8))
    begin
        genWriteData.timer_write = 'd1;
        genWriteData.timer_data  = ahbCmd.HWDATA[7:0];
        return genWriteData;
    end


    
    wrByteSel = write_addr[2:0];
    case(ahbCmd.HSIZE)
    HSIZE_B8://byte write
    begin                        
        tb_top.mem[write_addr] = ahbCmd.HWDATA[8*wrByteSel +: 8];
    end
    HSIZE_B16://2 bytes write
    begin
        for(int i = 0;i < 2;i++)
        begin            
            tb_top.mem[write_addr+i] = HWDATA[8*(wrByteSel+i) +: 8];
        end       
    end
    HSIZE_B32:
    begin
        for(int i = 0;i < 4;i++)
        begin            
            tb_top.mem[write_addr+i] = HWDATA[8*(wrByteSel+i) +: 8];
        end  
    end
    HSIZE_B64:
    begin
        for(int i = 0;i < 8;i++)
        begin            
            tb_top.mem[write_addr+i] = HWDATA[8*(wrByteSel+i) +: 8];
        end  
    end
    default:
    begin
        $error("no support");
        $finish;
    end
    endcase

endfunction
logic [63:0] debugOut;
function automatic logic [63:0] genReadData(input AHBCmd_t ahbCmd);    
    int addr_64bit;
    int byteSel;
    logic [63:0] rdatGen;
    logic[27:0] read_addr;

    read_addr = ahbCmd.HADDR[27:0];
    rdatGen = 'd0;

    case(ahbCmd.HSIZE)
    HSIZE_B8://byte write
    begin                
        byteSel = read_addr[2:0];
        rdatGen[8*byteSel +: 8] = tb_top.mem[read_addr];
    end
    HSIZE_B16://2 bytes write
    begin
        byteSel = read_addr[0];
        if (byteSel != 0) 
        begin
            $display("no align");
            $finish;
        end
        for(int i = 0;i < 2;i++)
        begin    
            rdatGen[8*(byteSel+i) +: 8] = tb_top.mem[read_addr+i];                    
        end       
    end
    HSIZE_B32:
    begin
        byteSel = read_addr[1:0];
        if (byteSel != 0) 
        begin
            $display("no align");
            $finish;
        end
        for(int i = 0;i < 4;i++)
        begin    
            rdatGen[8*(byteSel+i) +: 8] = tb_top.mem[read_addr+i];                    
        end  
    end
    HSIZE_B64:
    begin
        byteSel = read_addr[2:0];
        if (byteSel != 0) 
        begin
            $display("no align");
            $finish;
        end
        for(int i = 0;i < 8;i++)
        begin                        
            rdatGen[8*(byteSel+i) +: 8] = tb_top.mem[read_addr+i]; 
        end  
        debugOut = rdatGen;
    end
    default:
    begin
        $error("no support");
        $finish;
    end
    endcase
    genReadData = rdatGen;

endfunction


function automatic AHBCmd_t saveAHBCmd();

    saveAHBCmd = 'd0;
    saveAHBCmd.HWDATA = HWDATA  ;    
    saveAHBCmd.HSEL   = HSEL    ;
    saveAHBCmd.HPROT  = HPROT   ;
    saveAHBCmd.HWRITE = HWRITE  ;
    saveAHBCmd.HTRANS = HTRANS  ;
    saveAHBCmd.HSIZE  = HSIZE   ;
    saveAHBCmd.HADDR  = HADDR   ;
    saveAHBCmd.HBURST = HBURST  ;

    saveAHBCmd.cmdID = cmdID_reg++;
endfunction


function automatic AHBResult_t doAHBOp(input AHBCmd_t cmdIn);

    doAHBOp = 0;
    if ((ahbCmd.HTRANS != HTRANS_IDLE)) 
    begin
        //enter data phase and accept new cmd        
        if ( (ahbCmd.HTRANS == HTRANS_SEQ))
        begin
            $error("no support!");
            doAHBOp.HRESP = HRESP_ERROR;
            doAHBOp.HREADYOUT = 'd1;
        end
        else if (ahbCmd.HTRANS == HTRANS_IDLE)
        begin
            doAHBOp.HRESP = HRESP_OKAY;
            doAHBOp.HREADYOUT = 'd1;            
        end
        else if ( (ahbCmd.HTRANS == HTRANS_NONSEQ) & (ahbCmd.HBURST != HBURST_SINGLE) )
        begin
            $error("no support!");
            doAHBOp.HRESP = HRESP_ERROR;
            doAHBOp.HREADYOUT = 'd1;
        end
        else if ( (ahbCmd.HTRANS == HTRANS_NONSEQ) & (ahbCmd.HBURST == HBURST_SINGLE) & ahbCmd.HWRITE)
        begin
            //write             
            doAHBOp = genWriteData(ahbCmd);            
            doAHBOp.HREADYOUT = 'd1;
            doAHBOp.HRESP = HRESP_OKAY;
        end
        else if ( (ahbCmd.HTRANS == HTRANS_NONSEQ) & (ahbCmd.HBURST == HBURST_SINGLE) & ~ahbCmd.HWRITE)
        begin
            //read             
            doAHBOp.HRDATA = genReadData(ahbCmd);                        
            doAHBOp.HREADYOUT = 'd1;
            doAHBOp.HRESP = HRESP_OKAY;
        end  
    end
    else
    begin
        doAHBOp.HREADYOUT = 'd1;
        doAHBOp.HRESP = HRESP_OKAY;
    end
    doAHBOp.cmdID = ahbCmd.cmdID;

endfunction 



logic readyOfCmd = 'd1;
always @(posedge HCLK)
begin    
    HREADYOUT = readyOfCmd;
    if (readyOfCmd) 
    begin
        ahbCmd = saveAHBCmd();
        #2
        ahbCmd.HWDATA = HWDATA;       
        ahbRlt = doAHBOp(ahbCmd);
        readyOfCmd = ahbRlt.HREADYOUT;
        HRESP = ahbRlt.HRESP;
        HRDATA = ahbRlt.HRDATA;
    end
    else
    begin
        ahbRlt = doAHBOp(ahbCmd);
        readyOfCmd = ahbRlt.HREADYOUT;
        HRESP = ahbRlt.HRESP;
        HRDATA = ahbRlt.HRDATA;
    end
end


endmodule
