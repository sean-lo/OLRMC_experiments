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
    for (var, varname, varlabel) in zip([:MSE_difference, :MSE_ratio], ["mse_diff", "mse_ratio"], ["MSE improvement", "MSE improvement (rel)"])
        for (disjunctive_cuts_type, df) in zip(["linear", "linear3"], [combine_linear_df, combine_linear3_df])
            if kind == "pkn"
                var_df = df |>
                    x -> filter(
                        r -> (r.num_indices == Int(ceil(r.p * 1 * r.n))), 
                        x,
                    )
            elseif kind == "pknlog"
                var_df = df |>
                    x -> filter(
                        r -> (r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))), 
                        x,
                    )
            end
            var_unstack_df = var_df |>
                x -> unstack(
                    x, 
                    :n, :p, var,
                )
            pl = pl = Plots.plot(
                ylabel = varlabel,
                xlabel = L"Size ($n$)",
                xticks = n_range,
                yrange = (varname == "mse_diff" ? (-0.01, 0.120) : (-0.05, 0.2)),
                legend = :topright,
                tickfontsize = 10,
                legend_font_pointsize = 10,
            )
            for p in p_range
                Plots.plot!(
                    n_range, 
                    var_unstack_df[1:length(n_range),"$p"],
                    label = "p = $p",
                    color = colors[p],
                    shape = :circle,
                )
            end
            display(pl)
            savefig("postprocessing/plots/mc1_size_$(varname)_50_150_$(kind)_$(disjunctive_cuts_type).pdf")
        end
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

for (var, varname, varlabel) in zip([:MSE_difference, :MSE_ratio], ["mse_diff", "mse_ratio"], ["MSE improvement", "MSE improvement (rel)"])
    for (disjunctive_cuts_type, df) in zip(["linear", "linear3"], [combine_linear_df, combine_linear3_df])        
        var_unstack_df = df |>
            x -> filter(
                r -> (r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))), 
                x
            ) |>
            x -> unstack(
                x, 
                :n, :p, var,
            )
        pl = Plots.plot(
            ylabel = varlabel,
            xlabel = L"Size ($n$)",
            xticks = n_range,
            yrange = (varname == "mse_diff" ? (-0.0075, 0.020) : (-0.04, 0.08)),
            legend = :topright,
            tickfontsize = 10,
            legend_font_pointsize = 10,
        )
        for p in p_range
            Plots.plot!(
                n_range, 
                var_unstack_df[1:length(n_range), "$p"],
                label = "p = $p",
                color = colors[p],
                shape = :circle,
            )
        end
        display(pl)
        savefig("postprocessing/plots/mc1_size_$(varname)_50_250_pknlog_$(disjunctive_cuts_type).pdf")
    end
end