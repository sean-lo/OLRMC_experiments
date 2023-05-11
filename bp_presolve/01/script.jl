include("../../../MCBnB/src/matrix_completion.jl")
include("../../../MCBnB/src/utils.jl")
include("../../utils.jl")

using StatsBase
using Suppressor
using CSV
using DataFrames

# simple test case to quickly compile 
(A, indices) = generate_matrixcomp_data(1, 12, 12, 72, 0) # non-sparse version
(A, indices) = generate_matrixcomp_data(1, 12, 12, 25, 0) # sparse version
result = @timed @suppress rankk_presolve(indices, A, 1)
(A, indices) = generate_matrixcomp_data(2, 12, 12, 48, 0)
result = @timed @suppress rankk_presolve(indices, A, 2)
println("Compilation complete.")

args_df = DataFrame(CSV.File("$(@__DIR__)/args.csv"))

task_index = parse(Int, ARGS[1]) + 1
n_tasks = parse(Int, ARGS[2])
n_runs = 500
time_limit = nothing # CHANGE

println("Processing rows: $(collect(task_index:n_tasks:size(args_df, 1)))")

for row_index in task_index:n_tasks:size(args_df, 1)
    # Get paramters from args_df at row row_index
    k = args_df[row_index, :k]
    n = args_df[row_index, :n]
    p = args_df[row_index, :p]
    seed_index = args_df[row_index, :seed]
    kind = args_df[row_index, :kind]

    num_indices = string_to_num_indices(p, k, n, kind)

    records = []
    for seed in ((seed_index-1) * n_runs + 1):(seed_index * n_runs)
        local (A, indices) = generate_matrixcomp_data(k, n, n, num_indices, seed)
        local result = @timed @suppress rankk_presolve(indices, A, k)
        (indices_presolved, X_presolved) = result.value
        push!(records, (
            seed = seed,
            k = k,
            m = n,
            n = n, 
            p = p,
            num_indices = num_indices,
            time_taken = result.time,
            entries_presolved = sum(indices_presolved),
            memory = result.bytes,
        ))
        local result = nothing
    end
    CSV.write("$(@__DIR__)/records/$(row_index).csv", DataFrame(records))
end