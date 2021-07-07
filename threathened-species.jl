# ===========================================================
 # Threathened species toy problem, from
 # "Integer Linear Programming in Computational and Systems Biology",
 # by Dan Gusfield
 # Code written by @fredih for Julia v1.6
 # With NamedArrays v0.9.5, Cbc v0.8.0 and JuMP v0.21.7
 # alfredo.hernandez@ug.uchile.cl
# ===========================================================


using JuMP, NamedArrays, Cbc

function totalPreservedArea(var, area)
    return Sum(var)
end

regions = [:A, :B, :C, :D, :E]
animals = [:α, :β]
targets = NamedArray([64, 87], animals)
# Note: Dan messed up the cost for Area E. Even though the value from Table 1.1
# is 45, the one used is 25.
costs = NamedArray([97, 73, 22, 11, 25], regions)
# Note: Dan messed up the values for β, the values from Table 1.1 aren't the
# ones presented on equation 1.3 and Figure 1.1, which are the ones that give
# a matching result with the one presented in the book.
areas = NamedArray([24 83
                    36 16
                    00 19
                    15 00
                    40 18], (regions, animals))
threath = Model(Cbc.Optimizer)
set_optimizer_attribute(threath, "threads", Sys.CPU_THREADS)

# As an exercise, I decided to define the variables as binary first,
# and then to relax the problem
@variable(threath, x[r in regions], Bin)

for animal in animals
    @constraint(threath, sum(x[r]*areas[r,animal] for r in regions) >= targets[animal])
end

@objective(threath, Min, sum(x[r]*costs[r] for r in regions))
optimize!(threath)
areaBinary = [sum(value(x[r])*areas[r,animal]  for r in regions) for animal in animals]
print(threath)
print(solution_summary(threath, verbose=false))

# Now we solve the relaxation
relax_integrality(threath)
optimize!(threath)
print(threath)
print(solution_summary(threath, verbose=false))
areaRelaxed = [sum(value(x[r])*areas[r,animal]  for r in regions) for animal in animals]

println("============================================")
println("Preserved area in binary problem for α and β: ", areaBinary)
println("Preserved area in relaxed problem: α and β: ", areaRelaxed)
println("============================================")

# Now we solve the first modification of the problem
budget = 108.7
@objective(threath, Max, x[:B])
@constraint(threath, sum(x[r]*costs[r] for r in regions) <= budget)
optimize!(threath)
print(solution_summary(threath, verbose=false))
