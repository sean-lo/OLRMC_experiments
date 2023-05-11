using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using LaTeXStrings
using ColorSchemes

include("../utils.jl")

combine_df = CSV.read("mc1/summary.csv", DataFrame)

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
    :solve_time_relaxation_mean,
)
    
p_range = [2.0, 2.5, 3.0]
γ_range = [20.0, 80.0]
for (p, γ) in Iterators.product(
    p_range, 
    γ_range,
)
    node_selection_relative_gap_table = hcat(
        sort(
            filter(
                r -> (r.p == p && r.γ == γ && !r.use_disjunctive_cuts),
                node_selection_relative_gap_df,
            ),
            [:n, :altmin_flag],
        ) |> 
            x -> select!(
                x,
                :n, :altmin_flag,
                :bestfirst,
                :breadthfirst,
                :depthfirst,
            ),
        sort(
            filter(
                r -> (r.p == p && r.γ == γ && r.use_disjunctive_cuts),
                node_selection_relative_gap_df,
            ),
            [:n, :altmin_flag],
        ) |> 
            x -> select!(
                x,
                :bestfirst => :bestfirst_disjunctive,
                :breadthfirst => :breadthfirst_disjunctive,
                :depthfirst => :depthfirst_disjunctive,
            ) 
    ) |>
        x -> select(
            x, 
            :n, :altmin_flag,
            [
                :bestfirst,
                :breadthfirst,
                :depthfirst,
                :bestfirst_disjunctive,
                :breadthfirst_disjunctive,
                :depthfirst_disjunctive,
            ] .=> (x -> floatstring.(x))
            .=> [
                :bestfirst,
                :breadthfirst,
                :depthfirst,
                :bestfirst_disjunctive,
                :breadthfirst_disjunctive,
                :depthfirst_disjunctive,
            ],
        )
    node_selection_solve_time_table = hcat(
        sort(
            filter(
                r -> (r.p == p && r.γ == γ && !r.use_disjunctive_cuts),
                node_selection_solve_time_df,
            ),
            [:n, :altmin_flag],
        ) |> 
            x -> select!(
                x,
                :n, :altmin_flag,
                :bestfirst,
                :breadthfirst,
                :depthfirst,
            ),
        sort(
            filter(
                r -> (r.p == p && r.γ == γ && r.use_disjunctive_cuts),
                node_selection_solve_time_df,
            ),
            [:n, :altmin_flag],
        ) |> 
            x -> select!(
                x,
                :bestfirst => :bestfirst_disjunctive,
                :breadthfirst => :breadthfirst_disjunctive,
                :depthfirst => :depthfirst_disjunctive,
            ) 
    ) |>
        x -> select(
            x, 
            :n, :altmin_flag,
            [
                :bestfirst,
                :breadthfirst,
                :depthfirst,
                :bestfirst_disjunctive,
                :breadthfirst_disjunctive,
                :depthfirst_disjunctive,
            ] .=> (x -> floatstring.(x))
            .=> [
                :bestfirst,
                :breadthfirst,
                :depthfirst,
                :bestfirst_disjunctive,
                :breadthfirst_disjunctive,
                :depthfirst_disjunctive,
            ],
        )
    CSV.write("postprocessing/tables/mc1_relative_gap_$(p)_$(γ).csv", node_selection_relative_gap_table)
    CSV.write("postprocessing/tables/mc1_solve_time_$(p)_$(γ).csv", node_selection_solve_time_table)
end