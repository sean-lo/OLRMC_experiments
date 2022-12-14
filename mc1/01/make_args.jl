using CSV
using DataFrames

n_range = [10, 20, 30]
p_range = [2.0, 3.0]
noise_range = [0.1]
γ_range = [20.0, 80.0]
seed_range = collect(1:20)
use_disjunctive_cuts_range = [false, true]
node_selection_range = ["breadthfirst", "bestfirst", "depthfirst"]
altmin_flag_range = [false, true]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
    use_disjunctive_cuts = Bool[],
    node_selection = String[],
    altmin_flag = Bool[],
)
for (
    n, p, seed, noise, γ, use_disjunctive_cuts, node_selection, altmin_flag
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
    use_disjunctive_cuts_range,
    node_selection_range,
    altmin_flag_range,
)
    push!(args_df, 
        (
            1, n, p, seed, noise, γ,
            use_disjunctive_cuts,
            node_selection,
            altmin_flag,
        )
    )
end
CSV.write("$(@__DIR__)/args.csv", args_df)