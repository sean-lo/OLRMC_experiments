using CSV
using DataFrames

n_range = [50, 75, 100]
p_range = [2.0, 3.0]
noise_range = [0.1]
γ_range = [20.0, 80.0]
seed_range = collect(1:20)
params = vcat(
    [("none", false)], 
    vec(collect(Iterators.product(
        ["4", "43"],
        [false],
    ))),
)


args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    noise = Float64[],
    γ = Float64[],
    type = String[],
    add_Shor_valid_inequalities_iterative = Bool[],
)
for (
    n, p, seed, noise, γ,
    (
        type,
        add_Shor_valid_inequalities_iterative,
    ),
) in Iterators.product(
    n_range, 
    p_range, 
    seed_range, 
    noise_range,
    γ_range,
    params,
)
    push!(args_df, 
        (
            1, n, p, seed, noise, γ,
            type,
            add_Shor_valid_inequalities_iterative,
        )
    )
end
sort!(
    args_df, 
    [
        order(:n),
        order(:p),
        order(:γ),
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
        r -> (r.type == "43" && r.n != 100 && r.p != 3.0),
        args_df,
    ),
)
CSV.write("$(@__DIR__)/args.csv", args_df)