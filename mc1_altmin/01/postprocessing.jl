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
    :max_altmin_probability,
    :min_altmin_probability,
    :altmin_probability_decay_rate,
])
CSV.write(results_filepath, results_df)

filtered_results = deepcopy(results_df)
gdf = groupby(
    filtered_results, 
    [:k, :n, :p, :noise, :γ, 
    :max_altmin_probability,
    :min_altmin_probability,
    :altmin_probability_decay_rate,]
)
combine_df = combine(
    gdf,
    :time_taken => geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
    :nodes_explored => geomean,
    :solve_time_altmin => geomean,
)

decay_rate_time_taken_df = unstack(
    combine_df,
    [
        :n, :p, :γ, :max_altmin_probability, :min_altmin_probability,
    ],
    :altmin_probability_decay_rate,
    :time_taken_geomean,
)
decay_rate_relative_gap_df = unstack(
    combine_df,
    [
        :n, :p, :γ, :max_altmin_probability, :min_altmin_probability,
    ],
    :altmin_probability_decay_rate,
    :relative_gap_geomean,
)
decay_rate_nodes_explored_df = unstack(
    combine_df,
    [
        :n, :p, :γ, :max_altmin_probability, :min_altmin_probability,
    ],
    :altmin_probability_decay_rate,
    :nodes_explored_geomean,
)
decay_rate_solve_time_altmin_df = unstack(
    combine_df,
    [
        :n, :p, :γ, :max_altmin_probability, :min_altmin_probability,
    ],
    :altmin_probability_decay_rate,
    :solve_time_altmin_geomean,
)

filter(
    r -> (
        # r.n == 10
        r.p == 2.0
        && r.γ == 20.0
    ),
    combine_df,
)[
    !,
    Not([:k, :p, :noise, :γ, :max_altmin_probability])
]