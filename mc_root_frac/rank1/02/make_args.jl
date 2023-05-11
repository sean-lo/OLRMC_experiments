using CSV
using DataFrames

include("../../../utils.jl")

k_range = [1]
n_range = [50, 75, 100]
p_range = [2.0, 3.0]
noise_range = [0.1]
γ_range = [20.0, 80.0]
seed_range = collect(1:20)
params = [
    ("none", 0.0), 
    ("4", 1.0),
    ("43", 1.0),
    ("43", 0.5),
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
        r -> r.type == "43",
        args_df,
    ),
)
results_df = CSV.read("$(@__DIR__)/combined.csv", DataFrame) |>
    x -> transform(
        x, 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present 
        => ByRow(y -> array_to_string(y)) 
        => :type
    ) |> 
    x -> select(
        x, 
        [:k, :n, :p, :noise, :γ, :seed, :type,
        :add_Shor_valid_inequalities_fraction]
    )
new_args_df = antijoin(args_df, results_df, on = names(args_df))
CSV.write("$(@__DIR__)/args.csv", new_args_df)