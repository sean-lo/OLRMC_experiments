using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using DelimitedFiles
using LaTeXStrings
using ColorSchemes

include("../utils.jl")

MSE_df = CSV.read("mc_mse/data.csv", DataFrame) |> 
    x -> transform(
        x, 
        [:p, :k, :n, :kind] 
        => ByRow((p, k, n, kind) -> string_to_num_indices(p, k, n, kind))
        => :num_indices,
    )

results_df = vcat(
    [
        CSV.read(filepath, DataFrame)
        for filepath in glob("mc2_size/*/combined_*.csv")
    ]...
) |> 
    x -> unique(x, [:n, :p, :num_indices, :seed], keep=:last) |>
    x -> sort(x, [:n, :p, :num_indices, :seed])

filtered_MSE_df = MSE_df |>
    x -> filter(
        r -> (
            r.k == 2
            && r.num_indices ≤ r.n * r.n
        ),
        x
    ) |> 
    x -> unique(x, [:n, :p, :num_indices, :seed], keep=:last) |>
    x -> sort(x, [:n, :p, :num_indices, :seed])
results_df[!, "MSE_mf"] = filtered_MSE_df[!, :MSE_mf]
results_df[!, "MSE_isvd"] = filtered_MSE_df[!, :MSE_isvd]
    
CSV.write("mc2_size/combined.csv", results_df)

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
    :MSE_isvd => geomean,
    :MSE_mf => geomean,
)
sort!(
    combine_df, 
    [:n, :p, :num_indices],
)
combine_df[!, :k] .= 2
transform!(
    combine_df,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y) ./ y)
    => :MSE_ratio,
    [:MSE_all_initial_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y))
    => :MSE_difference,
    [:MSE_mf_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y) ./ y)
    => :MSE_mf_ratio,
    [:MSE_mf_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y))
    => :MSE_mf_difference,
    [:MSE_isvd_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y) ./ y)
    => :MSE_isvd_ratio,
    [:MSE_isvd_geomean, :MSE_all_geomean] 
    => ((x, y) -> (x .- y))
    => :MSE_isvd_difference,
)
show(
    combine_df[!, [
        :n, :p, :num_indices,
        :MSE_all_geomean,
        :MSE_mf_geomean,
        :MSE_isvd_geomean,
        :MSE_ratio, 
        :MSE_difference, 
        :MSE_mf_ratio, 
        :MSE_mf_difference, 
        :MSE_isvd_ratio, 
        :MSE_isvd_difference, 
    ]],
    allrows = true,
)
CSV.write("mc2_size/summary.csv", combine_df)