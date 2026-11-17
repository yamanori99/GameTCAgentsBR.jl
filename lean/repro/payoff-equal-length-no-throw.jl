# Reproducer: compute_payoff_outcome with equal-length vectors longer than size(U,1)
using GameTCAgentsBR

U = [2.0 2.0 2.0; 5.0 5.0 0.0; 8.0 0.0 0.0]
a = [0, 0, 0, 0, 100]
b = [0, 0, 0, 0, 100]
caught = nothing
try
    compute_payoff_outcome(a, b, U)
catch e
    global caught = e
end
if caught isa BoundsError &&
        length(a) == length(b) &&
        length(a) != size(U, 1)
    println("REPRODUCED payoff-equal-length-no-throw")
else
    error("expected BoundsError on equal 5-vectors with 3x3 U, got $(repr(caught))")
end
