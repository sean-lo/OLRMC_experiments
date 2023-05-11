using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using LaTeXStrings
using ColorSchemes

results_df = CSV.read("mc1/01/combined.csv", DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :noise, :γ,
    :use_disjunctive_cuts,
    :node_selection,
    :altmin_flag,
])
gdf = groupby(
    results_df, 
    [:k, :n, :p, :noise, :γ, :use_disjunctive_cuts, :node_selection, :altmin_flag]
)
combine_df = combine(
    gdf, 
    nrow,
    :num_indices => first => :num_indices,
    :nodes_explored => mean,
    :average_solve_time_relaxation => mean => :solve_time_relaxation_mean,
    :time_taken => geomean,
    :relative_gap_root_node => (x -> geomean(abs.(x))) => :relative_gap_root_node_geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
    :MSE_all_initial => geomean,
    :MSE_all => geomean,
)
transform!(
    combine_df,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y) ./ x)
    => :MSE_ratio,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y))
    => :MSE_difference,
)
CSV.write("mc1/summary.csv", combine_df)
