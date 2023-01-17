using CSV
using DataFrames

n_range = [10, 20, 30]
p_range = [2.0, 3.0]
noise_range = [0.1]
γ_range = [20.0, 80.0]
seed_range = collect(1:20)
altmin_flag_range = [true]
altmin_params = [
    (1.0, 0.005, 1.1),
    (1.0, 0.01, 1.1),
    (1.0, 0.02, 1.1),
    (1.0, 0.04, 1.1),
    (1.0, 0.005, 1.2),
    (1.0, 0.01, 1.2),
    (1.0, 0.02, 1.2),
    (1.0, 0.04, 1.2),
]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
    altmin_flag = Bool[],
    max_altmin_probability = Float64[],
    min_altmin_probability = Float64[],
    altmin_probability_decay_rate = Float64[],
)
for (
    n, p, seed, noise, γ, altmin_flag,
    (
        max_altmin_probability,
        min_altmin_probability,
        altmin_probability_decay_rate,
    )
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
    altmin_flag_range,
    altmin_params,
)
    push!(args_df, 
        (
            1, n, p, seed, noise, γ,
            altmin_flag,
            max_altmin_probability,
            min_altmin_probability,
            altmin_probability_decay_rate,
        )
    )
end
CSV.write("$(@__DIR__)/args.csv", args_df)