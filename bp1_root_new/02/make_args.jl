using CSV
using DataFrames

k_range = [1]
n_range = [10, 20, 30, 40, 50]
p_range = [2.0, 2.5, 3.0]
seed_range = collect(1:20)
kind_range = kind_range = [
    "pkn", 
    "pkn log_{10}(n)",
]
params = [
    (true, true, false, false),
    (false, false, false, true), 
    (true, false, false, true), 
    (true, true, false, true), 
    (true, true, true, true),
]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    kind = String[],
    presolve = Bool[],
    add_basis_pursuit_valid_inequalities = [],
    add_Shor_valid_inequalities = [],
    root_only = [],
)
for (k, n, p, seed, kind, (presolve, add_basis_pursuit_valid_inequalities, add_Shor_valid_inequalities, root_only)) in Iterators.product(k_range, n_range, p_range, seed_range, kind_range, params)
    push!(args_df, (k, n, p, seed, kind, presolve, add_basis_pursuit_valid_inequalities, add_Shor_valid_inequalities, root_only,))
end

V = [parse(Int, x[1:end-4]) for x in readlines("$(@__DIR__)/out.txt")]
args_df = args_df[setdiff(1:nrow(args_df), V), :]
args_df[:, :root_only]
CSV.write("$(@__DIR__)/args.csv", args_df)