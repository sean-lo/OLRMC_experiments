using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using StatsPlots

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :γ, :noise,
    :add_Shor_valid_inequalities,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
])
CSV.write(results_filepath, results_df)

gdf = groupby(
    results_df,
    [:k, :n, :p, :γ, :noise,
    :add_Shor_valid_inequalities,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,]
)
combine_df = combine(
    gdf, 
    :solve_time_relaxation => geomean, 
    :relative_gap_root_node 
    => (x -> geomean(abs.(x))) 
    => :relative_gap_root_node_geomean,
)