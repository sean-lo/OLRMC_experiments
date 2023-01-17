using CSV
using DataFrames

n_range = [10, 20, 30, 40, 50]
p_range = [2.0, 2.5, 3.0]
noise_range = [0.1]
γ_range = [80.0]
seed_range = collect(1:20)
kind_range = [
    "pkn", 
    "pkn log_{10}(n)",
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
        (2, n, p, seed, noise, γ, kind)
    )
end
CSV.write("$(@__DIR__)/args.csv", args_df)