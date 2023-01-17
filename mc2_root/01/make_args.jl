using CSV
using DataFrames

n_range = [10, 20, 30]
p_range = [2.0, 3.0]
noise_range = [0.1, 0.01]
γ_range = [20.0, 80.0]
seed_range = collect(1:20)
type_range = ["none", "4", "43", "432"]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
    type = String[],
)
for (
    n, p, seed, noise, γ, type
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
    type_range,
)
    push!(args_df, (2, n, p, seed, noise, γ, type,))
end
CSV.write("$(@__DIR__)/args.csv", args_df)