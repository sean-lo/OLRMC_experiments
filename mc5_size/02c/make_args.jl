using CSV
using DataFrames

include("../../utils.jl")

n_range = [125, 150]
p_range = [2.0, 2.5, 3.0]
noise_range = [0.1]
γ_range = [80.0]
seed_range = collect(1:50)
kind_range = [
    "pkn", 
    # "pkn log_{10}(n)",
    "pkn^{6/5} log_{10}(n) / 10^{1/5}",
]
args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
    kind = String[],
)
for (
    n, p, seed, noise, γ, kind, 
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
    kind_range,
)
    push!(args_df, 
        (5, n, p, seed, noise, γ, kind)
    )
end
sort!(
    args_df,
    [
        order(:n),
        order(:p, rev = true),
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
        [:k, :n, :p, :seed, :noise, :γ, :num_indices]
    )
new_args_df = antijoin(
    args_df, 
    results_df, 
    on = names(results_df)
)
# new_args_df = args_df
filter!(
    r -> (r.num_indices ≤ r.n * r.n),
    new_args_df
)
CSV.write("$(@__DIR__)/args.csv", new_args_df)