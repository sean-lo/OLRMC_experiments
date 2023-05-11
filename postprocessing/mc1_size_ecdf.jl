using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using StatsPlots
using CairoMakie
using LaTeXStrings
using ColorSchemes

id_cols = [:k, :n, :p, :num_indices, :γ, :disjunctive_cuts_type, :seed]
all_results_df = vcat(
    [
        CSV.read("mc1_size/linear/01/combined.csv", DataFrame),
        CSV.read("mc1_size/linear/02/combined.csv", DataFrame),
        CSV.read("mc1_size/linear3/03/combined.csv", DataFrame),
        CSV.read("mc1_size/linear3/04/combined.csv", DataFrame),
    ]...
) |>
    x -> unique(x, id_cols) |>
    x -> sort(x, id_cols) |>
    x -> filter(r -> (r.seed ≤ 20), x)

# 1: ECDFs with both linear and linear3, smaller n_range

p_range = [2.0, 2.5, 3.0]
n_range = [50, 75, 100, 125, 150]
colors = Dict(
    n => c
    for (n, c) in zip(
        n_range, 
        ColorSchemes.tol_muted.colors
        # get(ColorSchemes.viridis, collect(0:1:(length(n_range)-1)) ./(length(n_range)-1))
    )
)

for disjunctive_cuts_type in ["linear", "linear3"], p in p_range
    pl = Plots.plot(
        xscale = :log10,
        xrange = (10.0^-6, 10.0^0),
        xticks = 10.0 .^ (-6:1:0),
        ylabel = "Empirical CDF",
        xlabel = "Relative gap",
    )
    Plots.plot!(
        xtickfontsize = 10,
        ytickfontsize = 10,
        xlabelfontsize = 12,
        ylabelfontsize = 12,
        legendfontsize = 8,
    )
    for n in n_range
        println("$p, $n")
        pkn_relative_gaps = filter(
            r -> (
                r.n == n
                && r.p == p
                && r.num_indices == Int(ceil(p * 1 * n))
                && r.disjunctive_cuts_type == disjunctive_cuts_type
            ),
            all_results_df,
        )[:,:relative_gap]
        if length(pkn_relative_gaps) > 0
            StatsPlots.ecdfplot!(
                pkn_relative_gaps,
                color = colors[n],
                linewidth = 2,
                label = "n = $n, " * L"pkn" * " entries",
            )
        end
        pknlog_relative_gaps = filter(
            r -> (
                r.n == n
                && r.p == p
                && r.num_indices == Int(ceil(p * 1 * n * log10(n)))
                && r.disjunctive_cuts_type == disjunctive_cuts_type
            ),
            all_results_df,
        )[:,:relative_gap]
        if length(pknlog_relative_gaps) > 0
            StatsPlots.ecdfplot!(
                pknlog_relative_gaps,
                color = colors[n],
                style = :dash,
                linewidth = 2,
                label = "n = $n, " * L"pkn \ \log_{10}(n)" * " entries",
            )
        end
    end
    display(pl)
    savefig("postprocessing/plots/mc1_size_ecdf_$(p)_$(disjunctive_cuts_type).pdf")    
end

# 2. ECDFs with only log entries, linear and linear3, bigger n_range

p_range = [2.0, 2.5, 3.0]
n_range = [50, 75, 100, 125, 150, 200, 250]
colors = Dict(
    n => c
    for (n, c) in zip(
        n_range, 
        ColorSchemes.tol_muted.colors
        # get(ColorSchemes.viridis, collect(0:1:(length(n_range)-1)) ./(length(n_range)-1))
    )
)

for disjunctive_cuts_type in ["linear", "linear3"], p in p_range
    pl = Plots.plot(
        xscale = :log10,
        xrange = (10.0^-10, 10.0^0),
        xticks = 10.0 .^ (-10:1:0),
        ylabel = "Empirical CDF",
        xlabel = "Relative gap",
    )
    Plots.plot!(
        xtickfontsize = 10,
        ytickfontsize = 10,
        xlabelfontsize = 12,
        ylabelfontsize = 12,
        legendfontsize = 8,
    )
    for n in n_range
        pknlog_relative_gaps = filter(
            r -> (
                r.n == n
                && r.p == p
                && r.num_indices == Int(ceil(p * 1 * n * log10(n)))
                && r.disjunctive_cuts_type == disjunctive_cuts_type
            ),
            all_results_df,
        )[:,:relative_gap]
        if length(pknlog_relative_gaps) > 0
            StatsPlots.ecdfplot!(
                pknlog_relative_gaps,
                color = colors[n],
                linewidth = 2,
                label = "n = $n, " * L"pkn \ \log_{10}(n)" * " entries",
            )
        end
    end
    display(pl)
    savefig("postprocessing/plots/mc1_size_ecdf_pknlog_$(p)_$(disjunctive_cuts_type).pdf")    
end