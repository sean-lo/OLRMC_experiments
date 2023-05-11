using CSV
using DataFrames
using DelimitedFiles

include("../utils.jl")
include("../../mpco/utils.jl")

args_df = DataFrame(CSV.File("$(@__DIR__)/args.csv"))

for row_index in 1:size(args_df, 1)
    k = args_df[row_index, :k]
    n = args_df[row_index, :n]
    p = args_df[row_index, :p]
    seed = args_df[row_index, :seed]
    noise = args_df[row_index, :noise]
    γ = args_df[row_index, :γ]
    kind = args_df[row_index, :kind]

    num_indices = string_to_num_indices(p, k, n, kind)
    if !((n + n) * k ≤ num_indices ≤ n * n)
        continue
    end
    (A, indices) = generate_matrixcomp_data(
        k, n, n, num_indices, seed; 
        noise = true, ϵ = noise,
    )

    writedlm("$(@__DIR__)/data/$(row_index)_A.csv", A, ',')
    writedlm("$(@__DIR__)/data/$(row_index)_indices.csv", convert.(Int, indices), ',')
end