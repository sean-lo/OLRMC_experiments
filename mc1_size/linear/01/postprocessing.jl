using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using CairoMakie
using LaTeXStrings
using ColorSchemes

results_df = vcat(
    [
        CSV.read(filepath, DataFrame)
        for filepath in glob("mc1_size/linear/01/combined_*.csv")
    ]...
)
unique!(results_df, [:seed, :n, :p, :num_indices], keep=:last)
sort!(results_df, [
    :n, :p, :num_indices, :seed,
])
CSV.write("mc1_size/linear/01/combined.csv", results_df)

gdf = groupby(
    results_df,
    [:n, :p, :num_indices],
)
combine_df = combine(
    gdf, 
    nrow,
    :nodes_explored => mean,
    :average_solve_time_relaxation => mean => :solve_time_relaxation_mean,
    :time_taken => geomean,
    :relative_gap_root_node => (x -> geomean(abs.(x))) => :relative_gap_root_node_geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
    :MSE_all_initial => geomean,
    :MSE_all => geomean,
)
sort!(
    combine_df, 
    [
        :n, :p, :num_indices,
    ]
)
combine_df[!, :k] .= 1
transform!(
    combine_df,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y) ./ x)
    => :MSE_ratio,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y))
    => :MSE_difference,
)
CSV.write("$(@__DIR__)/summary.csv", combine_df)