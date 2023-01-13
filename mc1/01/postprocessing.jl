using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using StatsPlots

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :noise, :γ,
    :use_disjunctive_cuts,
    :node_selection,
    :altmin_flag,
])
CSV.write(results_filepath, results_df)

filtered_results = deepcopy(results_df)
gdf = groupby(
    filtered_results, 
    [:k, :n, :p, :noise, :γ, :use_disjunctive_cuts, :node_selection, :altmin_flag]
)
combine_df = combine(
    gdf,
    :solve_time_relaxation => geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
    :nodes_explored => mean,
)

node_selection_relative_gap_df = unstack(
    combine_df,
    [:n, :p, :γ, :use_disjunctive_cuts, :altmin_flag],
    :node_selection, 
    :relative_gap_geomean,
)
node_selection_solve_time_df = unstack(
    combine_df,
    [:n, :p, :γ, :use_disjunctive_cuts, :altmin_flag],
    :node_selection, 
    :solve_time_relaxation_geomean,
)
sort(
    filter(
        r -> (r.p == 2.0 && r.γ == 20.0),
        node_selection_relative_gap_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)
sort(
    filter(
        r -> (r.p == 2.0 && r.γ == 20.0),
        node_selection_solve_time_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)

sort(
    filter(
        r -> (r.p == 2.0 && r.γ == 80.0),
        node_selection_relative_gap_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)
sort(
    filter(
        r -> (r.p == 2.0 && r.γ == 80.0),
        node_selection_solve_time_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)

sort(
    filter(
        r -> (r.p == 3.0 && r.γ == 20.0),
        node_selection_relative_gap_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)
sort(
    filter(
        r -> (r.p == 3.0 && r.γ == 20.0),
        node_selection_solve_time_df,
    ),
    [:n, :altmin_flag, :use_disjunctive_cuts],
)


# TODO: at a start, a 4 * 3 table (node selection, altmin * use_disjunctive_cuts)
altmin_flag_relative_gap_df = unstack(
    combine_df,
    [:n, :p, :γ, :use_disjunctive_cuts, :node_selection],
    :altmin_flag, 
    :relative_gap_geomean,
)
altmin_flag_solve_time_df = unstack(
    combine_df,
    [:n, :p, :γ, :use_disjunctive_cuts, :node_selection],
    :altmin_flag, 
    :solve_time_relaxation_geomean,
)
use_disjunctive_cuts_relative_gap_df = unstack(
    combine_df,
    [:n, :p, :γ, :altmin_flag, :node_selection],
    :use_disjunctive_cuts, 
    :relative_gap_geomean,
)
use_disjunctive_cuts_solve_time_df = unstack(
    combine_df,
    [:n, :p, :γ, :altmin_flag, :node_selection],
    :use_disjunctive_cuts, 
    :solve_time_relaxation_geomean,
)
regularization_relative_gap_df = unstack(
    combine_df,
    [:n, :p, :use_disjunctive_cuts, :altmin_flag, :node_selection],
    :γ, 
    :relative_gap_geomean,
)
regularization_solve_time_df = unstack(
    combine_df,
    [:n, :p, :use_disjunctive_cuts, :altmin_flag, :node_selection],
    :γ, 
    :solve_time_relaxation_geomean,
)