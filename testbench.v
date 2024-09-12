module TopModule_tb;
    reg clk;
    reg we;
    reg reset;
    reg done;
    reg [3:0] addr;
    reg signed [7:0] var1;
    reg signed [7:0] var2;
    wire signed [7:0] RAM1 [5:0];
    wire done2;
    // Instantiate the TopModule
    SATSOLVER uut (
        .clk(clk),
        .we(we),
        .reset(reset),
        .done(done),
        .addr(addr),
        .var1(var1),
        .var2(var2),
        .RAM1(RAM1),
        .done2(done2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initial reset
        reset = 1;
        we = 0;
        done = 0;
        addr = 4'b0000;
        var1 = 8'd0;
        var2 = 8'd0;
        #10;
        
        reset = 0;
        we = 1;
        
        // Clause (x1 OR NOT x2)
        addr = 4'b0000; 
        var1 = 8'd1; 
        var2 = -8'd2; 
        #10;
        
        // Clause (x2 OR NOT x3)
        addr = 4'b0001; 
        var1 = 8'd2; 
        var2 = -8'd3; 
        #10;
        
        // Clause (NOT x1 OR x3)
        addr = 4'b0010; 
        var1 = -8'd1; 
        var2 = 8'd3; 
        #10;
        
        // Clause (x3 OR x2)
        addr = 4'b0011; 
        var1 = 8'd3; 
        var2 = 8'd2; 
        #20;

        // Signal done
        we = 0;
        done = 1;
        #20;
        
        wait (done2 == 1);
        #30; // Additional delay to ensure signal stability
        
        // Finish the simulation
        $finish;
    end

endmodule
