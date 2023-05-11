using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using LaTeXStrings
using ColorSchemes

results_filepath = "mc1_branch/01/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :noise, :γ,
    :use_disjunctive_cuts,
    :node_selection,
    :disjunctive_cuts_type,
])
CSV.write(results_filepath, results_df)

gdf = groupby(
    results_df, 
    [:k, :n, :p, :noise, :γ, 
    :node_selection, :disjunctive_cuts_type,
    ]
)
combine(gdf, nrow) |>
    x -> show(x, allrows = true)


combine_df = combine(
    gdf,
    nrow,
    :time_taken => geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
    :nodes_explored => mean,
) |>
    x -> sort!(
        x,
        [:n, :p, :γ, :node_selection, :disjunctive_cuts_type]
    )

disjunctive_cuts_type_relative_gap_df = combine_df |> 
    x -> unstack(
        x, 
        [:n, :p, :γ, :node_selection],
        :disjunctive_cuts_type,
        :relative_gap_geomean
    )
disjunctive_cuts_type_time_taken_df = combine_df |> 
    x -> unstack(
        x, 
        [:n, :p, :γ, :node_selection],
        :disjunctive_cuts_type,
        :time_taken_geomean
    )


n_range = [10, 20, 30, 40, 50]
p_range = [2.0, 3.0]
γ_range = [20.0, 80.0]
disjunctive_cuts_type_range = ["linear", "linear2", "linear3"]
node_selection_range = ["bestfirst", "depthfirst", "breadthfirst"]
labels = Dict(
    "linear" => "2 pieces",
    "linear2" => "3 pieces",
    "linear3" => "4 pieces",
)
colors = Dict(
    disjunctive_cuts_type => c
    for (disjunctive_cuts_type, c) in zip(
        disjunctive_cuts_type_range, 
        ColorSchemes.tol_bright.colors
        # get(ColorSchemes.viridis, collect(0:1:(length(n_range)-1)) ./(length(n_range)-1))
    )
)
shapes = Dict(
    "linear" => :circle,
    "linear2" => :dtriangle,
    "linear3" => :rect,
)
for (p, γ) in Iterators.product(p_range, γ_range)
    println(p, γ)
    Plots.plot(
        yscale = :log10,
        ylim = (10.0^(-1.0), 10.0^(4.0)),
        ylabel = "Runtime (s)",
        xticks = n_range,
        xlabel = L"Size ($n$)",
    )
    if γ == 80.0
        Plots.plot!(
            legend = :bottomright,
        )
    else
        Plots.plot!(
            legend = :none,
        )
    end
    for disjunctive_cuts_type in disjunctive_cuts_type_range
        Plots.plot!(
            n_range,
            filter(
                r -> (
                    r.p == p 
                    && r.γ == γ
                    && r.node_selection == "bestfirst"
                ),
                disjunctive_cuts_type_time_taken_df
            )[!, disjunctive_cuts_type],
            shape = shapes[disjunctive_cuts_type],
            color = colors[disjunctive_cuts_type],
            lw = 2,
            style = :solid,
            label = labels[disjunctive_cuts_type],
        )
    end
    Plots.plot!(
        xtickfontsize = 10,
        ytickfontsize = 10,
        xlabelfontsize = 12,
        ylabelfontsize = 12,
        legendfontsize = 10,
    )
    savefig("postprocessing/plots/mc1_branch_$(p)_$(γ).pdf")
end
