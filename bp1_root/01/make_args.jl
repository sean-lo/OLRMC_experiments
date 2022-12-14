using CSV
using DataFrames

n_range = [10, 20, 30, 40, 50]
p_range = [2.0, 2.5, 3.0]
seed_range = collect(1:20)
params = [
    (false, false, false), 
    (true, false, false), 
    (true, true, false), 
    (true, true, true),
]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    presolve = Bool[],
    add_basis_pursuit_valid_inequalities = [],
    add_Shor_valid_inequalities = [],
)
for (n, p, seed, (presolve, add_basis_pursuit_valid_inequalities, add_Shor_valid_inequalities)) in Iterators.product(n_range, p_range, seed_range, params)
    push!(args_df, (1, n, p, seed, presolve, add_basis_pursuit_valid_inequalities, add_Shor_valid_inequalities))
end
CSV.write("$(@__DIR__)/args.csv", args_df)