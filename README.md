A hardware accelerator is a specialized hardware component designed to perform specific computations more efficiently than a general-purpose CPU.
These can include graphics processing units (GPUs), field programmable gate arrays (FPGAs), application-specific integrated circuits (ASICs), and tensor processing units (TPUs)
A SAT solver, or Boolean satisfiability solver, is a computational tool used to determine if there exists an assignment of truth values to variables that makes a given Boolean formula true.
The problem it solves is known as the Boolean satisfiability problem (SAT), which is the problem of determining if there is a way to assign truth values to variables so that a given Boolean expression evaluates to true.

Implementing Kosaraju Algorithm for finding SCCs to solve 2-SAT problem :-
•Create the Implication Graph :
Construct a directed graph where each node represents a literal, and each directed edge represents an implication between literals.
•First DFS (Finishing Order Calculation) :
Perform a DFS traversal on the implication graph to determine the finish order of nodes. This step gives you the order in which nodes complete their exploration.
•Reverse the Implication Graph :
Reverse the direction of all edges in the graph to get the transposed graph.
•Second DFS (Find SCCs) :
Perform DFS on the transposed graph in the reverse of the finish order obtained from the first DFS. Each DFS run from an unvisited node identifies an SCC.
•Determine Satisfiability :
For each SCC, check if a variable and its negation are in the same SCC. If so, the formula is unsatisfiable. If  no such pair exists, the formula is satisfiable
