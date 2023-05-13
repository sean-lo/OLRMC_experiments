using CSV
using DataFrames

include("../../utils.jl")

k_range = [2]
n_range = [50, 75, 100]
p_range = [2.0, 3.0]
seed_range = collect(1:20)
kind_range = [
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
for (
    k, n, p, seed, kind, 
    (
        presolve, 
        add_basis_pursuit_valid_inequalities, 
        add_Shor_valid_inequalities, 
        root_only
    )
) in Iterators.product(
    k_range, n_range, p_range, seed_range, kind_range, 
    params
)
    push!(args_df, (k, n, p, seed, kind, presolve, add_basis_pursuit_valid_inequalities, add_Shor_valid_inequalities, root_only,))
end

sort!(
    args_df, 
    [
        order(:root_only, rev = true),
        order(:presolve),
        order(:add_basis_pursuit_valid_inequalities),
        order(:add_Shor_valid_inequalities, rev = true),
        order(:kind),
        order(:n), 
        order(:p),
    ]
)
transform!(
    args_df, 
    [:p, :k, :n, :kind] 
    => ByRow((p, k, n, kind) -> string_to_num_indices(p, k, n, kind))
    => :num_indices,
)
results_df = vcat(
    [
        CSV.read(filepath, DataFrame)
        for filepath in glob("$(@__DIR__)/combined_*.csv")
    ]...
) |>
    x -> select(
        x, 
        [
            :k, :n, :p, :seed, :num_indices,
            :root_only,
            :presolve,
            :add_basis_pursuit_valid_inequalities,
            :add_Shor_valid_inequalities,
        ]
    )
new_args_df = antijoin(
    args_df, 
    results_df, 
    on = names(results_df)
)
CSV.write("$(@__DIR__)/args.csv", new_args_df)