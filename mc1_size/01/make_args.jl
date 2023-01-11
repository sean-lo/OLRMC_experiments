using CSV
using DataFrames

n_range = [50, 75, 100, 125, 150]
p_range = [2.0, 2.5, 3.0]
noise_range = [0.1]
γ_range = [80.0]
seed_range = collect(1:20)

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
)
for (
    n, p, seed, noise, γ,
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
)
    push!(args_df, 
        (1, n, p, seed, noise, γ)
    )
end
CSV.write("$(@__DIR__)/args.csv", args_df)