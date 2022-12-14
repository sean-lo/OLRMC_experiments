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
results_df
CSV.write(results_filepath, results_df)

for g in groupby(
    results_df, [:k, :n, :p, :noise, :γ,
    :use_disjunctive_cuts,
    :node_selection,
    :altmin_flag,]
)
    if size(g, 1) != 20
        println("n = $(g.n[1]), p = $(g.p[1]), γ = $(g.γ[1]), use_disjunctive_cuts = $(g.use_disjunctive_cuts[1]), node_selection = $(g.node_selection[1]), altmin_flag = $(g.altmin_flag[1])")
        println(setdiff(1:20, g.seed))
    end
end

filter(
    r -> (r.n == 30),
    results_df
)
filter(
    r -> (r.node_selection == "depthfirst"),
    results_df
)
filter(
    r -> (!r.altmin_flag),
    results_df
)

