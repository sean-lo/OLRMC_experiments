using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using StatsPlots
using CairoMakie
using LaTeXStrings
using ColorSchemes
using Printf

include("../utils.jl")

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

# 1. smaller n_range, both pkn and pknlog

n_range = [50, 75, 100, 125, 150]
p_range = [2.0, 2.5, 3.0]
colors = Dict(
    p => c
    for (p, c) in zip(
        p_range,
        ColorSchemes.seaborn_colorblind6.colors,
    )
)


for disjunctive_cuts_type in ["linear", "linear3"]
    df = filter(
        r -> (r.disjunctive_cuts_type == disjunctive_cuts_type), 
        combine_df,
    )
    for kind in ["pkn", "pknlog"]
        pl = Plots.plot(
            yscale = :log,
            yticks = 10.0 .^ (-4:1:0),
            yrange = (10.0^-4, 10.0^0),
            ylabel = "Relative gap",
            xlabel = L"Size ($n$)",
            xticks = n_range,
        )
        if kind == "pkn"
            Plots.plot!(legend = :bottomleft)
        elseif kind == "pknlog"
            Plots.plot!(legend = :topright)
        end
        for p in p_range
            if kind == "pkn"
                Plots.plot!(
                    n_range,
                    filter(
                        r -> (
                            r.p == p
                            && r.num_indices == Int(ceil(r.p * 1 * r.n))
                        ), 
                        df
                    )[1:length(n_range), :relative_gap_geomean],
                    label = "p = $p",
                    color = colors[p],
                    shape = :circle,
                    style = :dash,
                    lw = 2,
                )
                Plots.plot!(
                    n_range,
                    filter(
                        r -> (
                            r.p == p
                            && r.num_indices == Int(ceil(r.p * 1 * r.n))
                        ), 
                        df
                    )[1:length(n_range), :relative_gap_root_node_geomean],
                    label = "p = $p, root node",
                    color = colors[p],
                    shape = :circle,
                    lw = 2,
                )
            elseif kind == "pknlog"
                Plots.plot!(
                    n_range,
                    filter(
                        r -> (
                            r.p == p
                            && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
                        ), 
                        df
                    )[1:length(n_range), :relative_gap_geomean],
                    label = "p = $p",
                    color = colors[p],
                    shape = :circle,
                    style = :dash,
                    lw = 2,
                )
                Plots.plot!(
                    n_range,
                    filter(
                        r -> (
                            r.p == p
                            && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
                        ), 
                        df
                    )[1:length(n_range), :relative_gap_root_node_geomean],
                    label = "p = $p, root node",
                    color = colors[p],
                    shape = :circle,
                    lw = 2,
                )
            end
        end
        Plots.plot!(
            xtickfontsize = 10,
            ytickfontsize = 10,
            xlabelfontsize = 12,
            ylabelfontsize = 12,
            legendfontsize = 10,
        )
        display(pl)
        savefig("postprocessing/plots/mc1_size_gap_50_150_$(kind)_$(disjunctive_cuts_type).pdf")
    end
end


for disjunctive_cuts_type in ["linear", "linear3"]
    df = filter(
        r -> r.disjunctive_cuts_type == disjunctive_cuts_type,
        combine_df
    )
    for kind in ["pknlog", "pkn"]
        if kind == "pknlog"
            kind_df = df |>
                x -> filter(
                    r -> (
                        r.num_indices == Int(ceil(r.n * r.p * log10(r.n)))
                        # && r.n in n_range
                    ),
                    x
                )
        elseif kind == "pkn"
            kind_df = df |>
                x -> filter(
                    r -> (
                        r.num_indices == Int(ceil(r.n * r.p))
                        # && r.n in n_range
                    ),
                    x
                )
        end
        kind_df |> 
            x -> select(
                x, 
                :n, :p, 
                :nodes_explored_mean 
                => (x -> round.(x, digits = 2))
                => :nodes_explored_mean,
                :solve_time_relaxation_mean 
                => (x -> round.(x, sigdigits = 4)) 
                => :solve_time_relaxation_mean,
                :time_taken_geomean
                => (x -> round.(min.(x, 3600.00), digits = 1)) 
                => :time_taken_geomean,
                [
                    :relative_gap_root_node_geomean, 
                    :relative_gap_geomean,
                ] .=> (x -> floatstring.(x))
                .=> [
                    :relative_gap_root_node_geomean, 
                    :relative_gap_geomean,
                ]
            ) |>
            x -> CSV.write("postprocessing/tables/mc1_size_$(kind)_$(disjunctive_cuts_type)_50_150.csv", x)
    end
end

# 2. larger n_range, just pknlog

n_range = [50, 75, 100, 125, 150, 200, 250]
p_range = [2.0, 2.5, 3.0]
colors = Dict(
    p => c
    for (p, c) in zip(
        p_range,
        ColorSchemes.seaborn_colorblind6.colors,
    )
)

for disjunctive_cuts_type in ["linear", "linear3"]
    df = filter(
        r -> r.disjunctive_cuts_type == disjunctive_cuts_type,
        combine_df
    )
    pl = Plots.plot(
        yscale = :log,
        yticks = 10.0 .^ (-8:1:0),
        yrange = (10.0^-8, 10.0^0),
        ylabel = "Relative gap",
        xlabel = L"Size ($n$)",
        xticks = n_range,
        legend = :topright,
    )
    for p in p_range
        Plots.plot!(
            n_range,
            filter(
                r -> (
                    r.p == p
                    && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
                ), 
                df
            )[1:length(n_range), :relative_gap_geomean],
            label = "p = $p",
            color = colors[p],
            shape = :circle,
            style = :dash,
            lw = 2,
        )
        Plots.plot!(
            n_range,
            filter(
                r -> (
                    r.p == p
                    && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
                ), 
                df
            )[1:length(n_range), :relative_gap_root_node_geomean],
            label = "p = $p, root node",
            color = colors[p],
            shape = :circle,
            lw = 2,
        )
    end
    display(pl)
    Plots.plot!(
        xtickfontsize = 10,
        ytickfontsize = 10,
        xlabelfontsize = 12,
        ylabelfontsize = 12,
        legendfontsize = 10,
    )
    savefig("postprocessing/plots/mc1_size_gap_50_250_pknlog_$(disjunctive_cuts_type).pdf")
end
