using CSV
using DataFrames

k_range = [2]
n_range = [10, 20, 30]
p_range = [2.0, 3.0]
noise_range = [0.1]
γ_range = [80.0]
seed_range = collect(1:20)
params = [
    ("none", 0.0), 
    ("4", 1.0),
    ("43", 0.5),
    ("43", 1.0),
]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    noise = Float64[],
    γ = Float64[],
    seed = Int[],
    type = String[],
    add_Shor_valid_inequalities_fraction = Float64[],
)
for (
    k, n, p, noise, γ, seed,
    (
        type,
        add_Shor_valid_inequalities_fraction,
    ),
) in Iterators.product(
    k_range,
    n_range, 
    p_range, 
    noise_range,
    γ_range,
    seed_range, 
    params,
)
    push!(args_df, 
        (
            k, n, p, noise, γ, seed,
            type,
            add_Shor_valid_inequalities_fraction,
        )
    )
end
sort!(
    args_df,
    [
        order(:type),
        order(:n),
        order(:p),
    ]
)
args_df = vcat(
    filter(
        r -> r.type == "none",
        args_df, 
    ),
    filter(
        r -> r.type == "4",
        args_df, 
    ),
    filter(
        r -> (
            r.type == "43"
            && r.add_Shor_valid_inequalities_fraction == 0.5
        ),
        args_df, 
    ),
    filter(
        r -> (
            r.type == "43"
            && r.add_Shor_valid_inequalities_fraction == 1.0
        ),
        args_df, 
    ),
)
CSV.write("$(@__DIR__)/args.csv", args_df)