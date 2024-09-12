module SATSOLVER #(
    parameter CLAUSE_SIZE = 4,
    parameter IMPL_SIZE = CLAUSE_SIZE * 2,
    parameter Nodes = 6
)(
    input wire clk,
    input wire we,
    input wire reset,
    input wire done,
    input wire [$clog2(CLAUSE_SIZE)-1:0] addr,
    input wire signed [7:0] var1,
    input wire signed [7:0] var2,
    output reg signed [7:0] RAM1 [Nodes-1:0],
    output reg done2
);
    
    wire signed [7:0] ram1_out [CLAUSE_SIZE-1:0];
    wire signed [7:0] ram2_out [CLAUSE_SIZE-1:0];
    wire signed [7:0] ramX [IMPL_SIZE-1:0];
    wire signed [7:0] ramY [IMPL_SIZE-1:0];
    wire signed [7:0] rev_ramX [IMPL_SIZE-1:0];
    wire signed [7:0] rev_ramY [IMPL_SIZE-1:0];
    wire signed [7:0] finish_order [5:0];
   
    StoreSATClauses #(.CLAUSE_SIZE(CLAUSE_SIZE)) store (
        .clk(clk),
        .we(we),
        .reset(reset),
        .addr(addr),
        .var1(var1),
        .var2(var2),
        .ram1_out(ram1_out),
        .ram2_out(ram2_out)
    );

    ImplicationGraph #(.CLAUSE_SIZE(CLAUSE_SIZE), .IMPL_SIZE(IMPL_SIZE)) implication (
        .done(done),
        .reset(reset),
        .ram1_in(ram1_out),
        .ram2_in(ram2_out),
        .ramX(ramX),
        .ramY(ramY)
    );
   
    ReverseGraph #(.IMPL_SIZE(IMPL_SIZE)) reverse_graph (
        .ramX(ramX),
        .ramY(ramY),
        .rev_ramX(rev_ramX),
        .rev_ramY(rev_ramY)
    );
    
    DFS1Traversal trav1 (
        .clk(clk),
        .rst(reset),
        .done(done),
        .ramX(ramX),
        .ramY(ramY),
        .finish_order(finish_order),
        .done3(done3)
    );
    
    dfs2traversal trav2 (
         .clk(clk),
         .reset(reset),
         .done3(done3),
         .finish_order(finish_order),
         .rev_ramX(rev_ramX),
         .rev_ramY(rev_ramY),
         .RAM1(RAM1),
         .done2(done2)
    );
endmodule

module StoreSATClauses #(
    parameter CLAUSE_SIZE = 4
)(
    input wire clk,
    input wire we,
    input wire reset,
    input wire [$clog2(CLAUSE_SIZE)-1:0] addr,
    input wire signed [7:0] var1,
    input wire signed [7:0] var2,
    output reg signed [7:0] ram1_out [CLAUSE_SIZE-1:0],
    output reg signed [7:0] ram2_out [CLAUSE_SIZE-1:0]
);
    reg signed [7:0] ram1 [CLAUSE_SIZE-1:0];
    reg signed [7:0] ram2 [CLAUSE_SIZE-1:0];

    always@(posedge clk)begin
      integer i;
      if(reset)begin
        for (i = 0; i < CLAUSE_SIZE; i = i + 1) begin
            ram1[i] = 8'b0;
            ram2[i] = 8'b0;
        end
      end
    end

    always @(posedge clk) begin
        if (we) begin
            ram1[addr] <= var1;
            ram2[addr] <= var2;
        end
    end

    // Output the contents of the RAM arrays on each clock cycle
    always @(posedge clk) begin
        integer i;
        for (i = 0; i < CLAUSE_SIZE; i = i + 1) begin
            ram1_out[i] <= ram1[i];
            ram2_out[i] <= ram2[i];
        end
    end
endmodule

module ImplicationGraph #(
    parameter CLAUSE_SIZE = 4,
    parameter IMPL_SIZE = CLAUSE_SIZE * 2
)(
    input wire done,
    input wire reset,
    input wire signed [7:0] ram1_in [CLAUSE_SIZE-1:0],
    input wire signed [7:0] ram2_in [CLAUSE_SIZE-1:0],
    output reg signed [7:0] ramX [IMPL_SIZE-1:0],
    output reg signed [7:0] ramY [IMPL_SIZE-1:0]
);
    integer i;
    always @(*) begin
        if(reset) begin
            for (i = 0; i < CLAUSE_SIZE; i = i + 1) begin
                ramX[2*i] = 0;
                ramY[2*i] = 0;
                ramX[2*i + 1] = 0;
                ramY[2*i + 1] = 0;
            end
        end
    end
    always @(*) begin
        if(done) begin
            for (i = 0; i < CLAUSE_SIZE; i = i + 1) begin
                ramX[2*i] = -ram1_in[i];
                ramY[2*i] = ram2_in[i];
                ramX[2*i + 1] = -ram2_in[i];
                ramY[2*i + 1] = ram1_in[i];
            end
        end
    end
endmodule


module DFS1Traversal#(
   parameter Nodes = 6
)(
    input wire clk,
    input wire rst,
    input wire done,
    input wire signed [7:0] ramX [7:0],
    input wire signed [7:0] ramY [7:0],
    output reg signed [7:0] finish_order [Nodes-1 :0],
    output reg done3
);
    typedef enum reg [2:0] {INIT, SEARCH, BACKTRACK, FINISH} state_t;
    state_t state;

    reg signed [7:0] visited_stack [7:0];
    reg signed [7:0] elem_stack [7:0];
    reg [2:0] finish_sp;
    reg signed [7:0] current_node;
    reg signed [7:0] next_node;
    reg [2:0] vcounter;
    reg [2:0] ecounter;
    integer i, j, k;
    reg flag4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= INIT;
            finish_sp <= 0;
            done3 <= 0;
            current_node <= 0;
            next_node <= 0;
            flag4 <= 0;
            vcounter <= 0;
            ecounter <= 0;
            for(k = 0; k < 8; k = k + 1) begin
                visited_stack[k] <= 0;
                elem_stack[k] <= 0;
                finish_order[k] <= 0;  // Only initialize the used portion of finish_order
            end
        end else begin
            case (state)
                INIT: begin
                    if (done) begin
                        visited_stack[0] <= ramX[0];
                        elem_stack[0] <= ramX[0];
                        visited_stack[1] <= ramY[0];
                        elem_stack[1] <= ramY[0];
                        current_node <= ramY[0];
                        vcounter <= 2;
                        ecounter <= 2;
                        state <= SEARCH;
                    end
                end
                SEARCH: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (ramX[i] == current_node) begin
                            next_node = ramY[i];
                            for (j = 0; j < 8; j = j + 1) begin
                                if(visited_stack[j] == next_node)begin 
                                    flag4 = 1;
                                end
                            end
                            if (flag4) begin
                                flag4 = 0;
                                continue;
                            end    
                            current_node <= next_node;
                            visited_stack[vcounter] <= next_node;
                            elem_stack[ecounter] <= next_node;
                            vcounter <= vcounter + 1;
                            ecounter <= ecounter + 1;
                            state <= SEARCH;
                            break;
                        end
                    end
                    if(i == 8) begin
                        state <= BACKTRACK;
                    end
                end
                BACKTRACK: begin
                    flag4 <= 0;
                    finish_order[finish_sp] <= current_node;
                    finish_sp <= finish_sp + 1;
                    ecounter <= ecounter - 1;
                    if (ecounter == 1)begin
                        state <= FINISH;
                    end
                    else begin
                        current_node <= elem_stack[ecounter - 2];
                        elem_stack[ecounter - 1] <= 0;
                        state <= SEARCH;
                    end
                end
                FINISH: done3 <= 1;
            endcase
        end
    end
endmodule



module ReverseGraph #(
    parameter IMPL_SIZE = 8
)(
    input wire signed [7:0] ramX [IMPL_SIZE-1:0],
    input wire signed [7:0] ramY [IMPL_SIZE-1:0],
    output reg signed [7:0] rev_ramX [IMPL_SIZE-1:0],
    output reg signed [7:0] rev_ramY [IMPL_SIZE-1:0]
);
    integer i;
    always @(*) begin
        for (i = 0; i < IMPL_SIZE; i = i + 1) begin
            rev_ramX[i] = ramY[i];
            rev_ramY[i] = ramX[i];
        end
    end
endmodule


module dfs2traversal#(
   parameter Nodes = 6
)(
    input clk,
    input reset,
    input done3,
    input signed [7:0] finish_order [5:0],
    input signed [7:0] rev_ramX [7:0],
    input signed [7:0] rev_ramY [7:0],
    output reg signed [7:0] RAM1 [Nodes-1:0],
    output reg done2
);
    integer signed order_sp;
    reg signed [7:0] visited [7:0];
    reg signed [7:0] current_node;
    reg signed [7:0] next_node;
    reg [2:0] ram1_index;
    reg flag;
    reg flag2;
    reg [2:0] vcounter;
    integer i, j, k;

    typedef enum reg [2:0] {CHECK_ORDER, POP_ELEMENT, CHECK_VISITED, FIND_NEXT, FINISH, RESET_SCC} state_t;
    state_t state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= CHECK_ORDER;
            order_sp <= Nodes - 1;
            done2 <= 0;
            ram1_index <= 0;
            flag <= 0;
            flag2 <= 0;
            vcounter <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                RAM1[i] <= 8'd0;
                visited[i] <= 8'd0;
            end
        end else begin
            case (state)
                CHECK_ORDER: begin
                    flag <= 1'b0;
                    if (done3) begin
                        if (order_sp >= 0)begin
                            state <= POP_ELEMENT;
                        end
                        else begin
                            state <= FINISH;
                        end
                    end
                end
                POP_ELEMENT: begin
                    current_node <= finish_order[order_sp];
                    order_sp <= order_sp - 1;
                    state <= CHECK_VISITED;
                end
                CHECK_VISITED: begin
                    flag2 <= 1'b0;
                    for (i = 0; i < 8; i = i + 1) begin
                        if (visited[i] == current_node)begin
                            flag = 1'b1;
                        end
                    end
                    if (flag == 1'b1)
                       state <= CHECK_ORDER;
                    else begin
                        RAM1[ram1_index] <= current_node;
                        ram1_index <= ram1_index + 1;
                        visited[vcounter] <= current_node;
                        vcounter <= vcounter + 1;
                        state <= FIND_NEXT;
                    end
                end
                FIND_NEXT: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        if (rev_ramX[j] == current_node) begin
                            next_node = rev_ramY[j];
                            for (k = 0; k < 8; k = k + 1) begin
                                if (visited[k] == next_node)
                                  flag2 = 1;
                            end
                            if (flag2) begin
                                flag2 = 0;
                                continue;
                            end
                            RAM1[ram1_index] <= next_node;
                            ram1_index <= ram1_index + 1;
                            current_node <= next_node;
                            visited[vcounter] <= next_node;
                            vcounter <= vcounter + 1;
                            state <= FIND_NEXT;
                            break;
                        end
                    end
                    if (j == 8)begin
                        state <= RESET_SCC;
                    end   
                end
                RESET_SCC: begin
                    for (i = 0; i < Nodes -1; i = i + 1) begin
                        RAM1[i] <= 8'd0;
                    end
                    flag2 <= 0;
                    ram1_index <= 0;
                    current_node <= 8'd0;
                    state <= CHECK_ORDER;
                end
                FINISH: done2 <= 1'b1;
            endcase
        end
    end
endmodule
