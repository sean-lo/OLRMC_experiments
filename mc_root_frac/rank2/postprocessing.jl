using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using ColorSchemes
using LaTeXStrings

all_results_df = vcat(
    CSV.read("mc_root_frac/rank2/03/combined.csv", DataFrame),
    CSV.read("mc_root_frac/rank2/04/combined.csv", DataFrame),
)
sort!(all_results_df, [
    :k, :n, :p, :seed, :γ,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
    :add_Shor_valid_inequalities_fraction,
])
gdf = groupby(all_results_df, [
    :n, :p, :γ, 
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
    :add_Shor_valid_inequalities_fraction
])
combine_df = combine(gdf,
    nrow,
    :solve_time_relaxation 
    => geomean,
    :relative_gap_root_node 
    => (x -> geomean(abs.(x))) 
    => :relative_gap_root_node_geomean,
)
sort!(
    combine_df, 
    [
        order(:n), 
        order(:p),
        order(:Shor_valid_inequalities_noisy_rank1_num_entries_present, rev = true),
        order(:add_Shor_valid_inequalities_fraction)
    ]
)
CSV.write("mc_root_frac/rank2/summary.csv", combine_df)