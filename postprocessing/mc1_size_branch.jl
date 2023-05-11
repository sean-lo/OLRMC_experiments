using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using CairoMakie
using LaTeXStrings
using ColorSchemes

id_cols = [:k, :n, :p, :num_indices, :γ, :disjunctive_cuts_type, :seed]
all_data = vcat(
    CSV.read("mc1_size/linear/01/combined.csv", DataFrame),
    CSV.read("mc1_size/linear/02/combined.csv", DataFrame),
    CSV.read("mc1_size/linear3/03/combined.csv", DataFrame),
    CSV.read("mc1_size/linear3/04/combined.csv", DataFrame),
) |>
    x -> unique(x, id_cols) |>
    x -> sort(x, id_cols) |>
    x -> filter(r -> (r.seed ≤ 20), x)

gdf = groupby(
    all_data,
    setdiff(id_cols, [:seed]) 
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

pknlog_combine_df = filter(
    r -> (
        r.num_indices == Int(ceil(r.n * r.k * r.p * log10(r.n)))
        && r.γ == 80.0
    ), 
    combine_df
)
unstack(
    filter(r -> r.disjunctive_cuts_type == "linear", pknlog_combine_df),
    :n, :p, :relative_gap_root_node_geomean
)
unstack(
    filter(r -> r.disjunctive_cuts_type == "linear3", pknlog_combine_df),
    :n, :p, :relative_gap_root_node_geomean
)
unstack(
    filter(r -> r.disjunctive_cuts_type == "linear", pknlog_combine_df),
    :n, :p, :relative_gap_geomean
)
unstack(
    filter(r -> r.disjunctive_cuts_type == "linear3", pknlog_combine_df),
    :n, :p, :relative_gap_geomean
)


n_range = unique(pknlog_combine_df[!, :n])
p_range = [2.0, 2.5, 3.0]
colors = Dict(
    p => c
    for (p, c) in zip(
        p_range,
        ColorSchemes.seaborn_colorblind6.colors
    )
)
pl = Plots.plot(
    yscale = :log10,
    yticks = 10.0 .^ (-4:1:0),
    yrange = (10.0^-4, 10.0^0),
    ylabel = "Relative gap",
    xlabel = L"Size ($n$)",
    xticks = n_range,
)
for p in p_range
    if p == 2.5
        continue
    end
    Plots.plot!(
        n_range,
        unstack(
            filter(r -> r.disjunctive_cuts_type == "linear", pknlog_combine_df),
            :n, :p, :relative_gap_geomean
        )[!, "$p"],
        shape = :circle,
        style = :dash,
        color = colors[p],
        label = "p = $p, 2 breakpoints"
    )
    Plots.plot!(
        n_range,
        unstack(
            filter(r -> r.disjunctive_cuts_type == "linear3", pknlog_combine_df),
            :n, :p, :relative_gap_geomean
        )[!, "$p"],
        shape = :circle,
        style = :dashdot,
        color = colors[p],
        label = "p = $p, 4 breakpoints"
    )
    Plots.plot!(
        n_range,
        unstack(
            filter(r -> r.disjunctive_cuts_type == "linear", pknlog_combine_df),
            :n, :p, :relative_gap_root_node_geomean
        )[!, "$p"],
        shape = :circle,
        style = :solid,
        color = colors[p],
        label = "p = $p, root node"
    )
end
Plots.plot!(
    xtickfontsize = 10,
    ytickfontsize = 10,
    xlabelfontsize = 12,
    ylabelfontsize = 12,
    legendfontsize = 10,
)
display(pl)
savefig("postprocessing/plots/mc1_size_gap_pknlog_linear_linear3.pdf")