using CSV
using DataFrames

k_range = [1, 2]
n_range = [10, 20, 30, 40, 50, 75, 100]
p_range = [2.0, 2.5, 3.0]
seed_range = collect(1:20)
kind_range = ["pkn", "pkn log10(n)", "pkn^1.5/sqrt(10)", "pkn^2/10"]

args_df = DataFrame(
    k = Int[],
    n = Int[],
    p = Float64[],
    seed = Int[],
    kind = String[],
)
for (k, n, p, seed, kind) in Iterators.product(k_range, n_range, p_range, seed_range, kind_range)
    push!(args_df, (k, n, p, seed, kind))
end
CSV.write("$(@__DIR__)/args.csv", args_df)