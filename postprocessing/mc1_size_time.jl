using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using StatsPlots
using CairoMakie
using LaTeXStrings
using ColorSchemes

combine_linear_df = vcat(
    CSV.read("mc1_size/linear/01/summary.csv", DataFrame),
    CSV.read("mc1_size/linear/02/summary.csv", DataFrame),
)
combine_linear3_df = vcat(
    CSV.read("mc1_size/linear3/03/summary.csv", DataFrame),
    CSV.read("mc1_size/linear3/04/summary.csv", DataFrame),
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

for kind in ["pkn", "pknlog"]
    for (disjunctive_cuts_type, df) in zip(["linear", "linear3"], [combine_linear_df, combine_linear3_df])
        if kind == "pkn"
            solve_time_relaxation_df = df |>
                x -> filter(
                    r -> (r.num_indices == Int(ceil(r.p * 1 * r.n))), 
                    x,
                )
        elseif kind == "pknlog"
            solve_time_relaxation_df = df |>
                x -> filter(
                    r -> (r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))), 
                    x,
                )
        end
        solve_time_relaxation_unstack_df = solve_time_relaxation_df |>
            x -> unstack(
                x, 
                :n, :p,
                :solve_time_relaxation_mean,
            )
        pl = Plots.plot(
            yscale = :log,
            ylabel = "Runtime (s)",
            xlabel = L"Size ($n$)",
            xticks = n_range,
            yticks = 10.0 .^ (0:1:4),
            yrange = (10.0^0, 10.0^4),
            legend = :topleft,
            tickfontsize = 10,
            legend_font_pointsize = 10,
        )
        for p in p_range
            Plots.plot!(
                n_range, 
                solve_time_relaxation_unstack_df[1:length(n_range),"$p"],
                label = "p = $p",
                color = colors[p],
                shape = :circle,
            )
        end
        display(pl)
        savefig("postprocessing/plots/mc1_size_time_50_150_$(kind)_$(disjunctive_cuts_type).pdf")
    end
end

n_range = [50, 75, 100, 125, 150, 200, 250]
p_range = [2.0, 2.5, 3.0]
colors = Dict(
    p => c
    for (p, c) in zip(
        p_range,
        ColorSchemes.seaborn_colorblind6.colors,
    )
)

for (disjunctive_cuts_type, df) in zip(["linear", "linear3"], [combine_linear_df, combine_linear3_df])        
    solve_time_relaxation_unstack_df = df |>
        x -> filter(
            r -> (r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))), 
            x
        ) |>
        x -> unstack(
            x, 
            :n, :p,
            :solve_time_relaxation_mean,
        )
    pl = Plots.plot(
        yscale = :log,
        ylabel = "Runtime (s)",
        xlabel = L"Size ($n$)",
        xticks = n_range,
        yticks = 10.0 .^ (0:1:4),
        yrange = (10.0^0, 10.0^4),
        legend = :topleft,
        tickfontsize = 10,
        legend_font_pointsize = 10,
    )
    for p in p_range
        Plots.plot!(
            n_range, 
            solve_time_relaxation_unstack_df[1:length(n_range),"$p"],
            label = "p = $p",
            color = colors[p],
            shape = :circle,
        )
    end
    display(pl)
    savefig("postprocessing/plots/mc1_size_time_50_250_pknlog_$(disjunctive_cuts_type).pdf")
end