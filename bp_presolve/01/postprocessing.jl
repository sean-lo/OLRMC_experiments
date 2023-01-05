using CSV
using Glob
using DataFrames
using StatsBase
using CairoMakie

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :seed,
    :k, :n, :p, :num_indices
])
CSV.write(results_filepath, results_df)

groupby(results_df, [:k, :n, :p, :num_indices])