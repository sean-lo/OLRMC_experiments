using CSV
using Glob
using DataFrames
using Plots
using StatsPlots
using StatsBase
using CairoMakie
using LaTeXStrings
using ColorSchemes

include("../utils.jl")

combine_df = CSV.read("mc_root_frac/rank1/summary.csv", DataFrame)

solve_time_df = combine_df |> 
    x -> filter(
        r -> (
            r.p == 2.0
            && r.Shor_valid_inequalities_noisy_rank1_num_entries_present in ["Int64[]", "[4]", "[4, 3]"]
            && r.add_Shor_valid_inequalities_fraction in [0.0, 0.5, 1.0]
        ),
        x
    ) |>
    x -> transform(
        x, 
        [:Shor_valid_inequalities_noisy_rank1_num_entries_present, :add_Shor_valid_inequalities_fraction] =>
        ((x, y) -> string.(x) .* ":" .* string.(y))
        => :param,
    ) |> 
    x -> unstack(
        x, 
        [:n, :p, :γ], :param, :solve_time_relaxation_geomean
    ) |>
    x -> transform(
        x, 
        "Int64[]:0.0" => (x -> 1.0) => "Int64[]:0.0_ratio",
        ["Int64[]:0.0", "[4]:1.0"] =>
        ((x, y) -> y ./ x)
        => "[4]:1.0_ratio",
        ["Int64[]:0.0", "[4, 3]:0.5"] =>
        ((x, y) -> y ./ x)
        => "[4, 3]:0.5_ratio",
        ["Int64[]:0.0", "[4, 3]:1.0"] =>
        ((x, y) -> y ./ x)
        => "[4, 3]:1.0_ratio",
    )

root_node_gap_df = combine_df |> 
    x -> filter(
        r -> (
            r.p == 2.0
            && r.Shor_valid_inequalities_noisy_rank1_num_entries_present in ["Int64[]", "[4]", "[4, 3]"]
            && r.add_Shor_valid_inequalities_fraction in [0.0, 0.5, 1.0]
        ),
        x
    ) |>
    x -> transform(
        x, 
        [:Shor_valid_inequalities_noisy_rank1_num_entries_present, :add_Shor_valid_inequalities_fraction] =>
        ((x, y) -> string.(x) .* ":" .* string.(y))
        => :param,
    ) |> 
    x -> unstack(
        x, 
        [:n, :p, :γ], :param, :relative_gap_root_node_geomean
    ) |>
    x -> transform(
        x, 
        "Int64[]:0.0" => (x -> 1.0) => "Int64[]:0.0_ratio",
        ["Int64[]:0.0", "[4]:1.0"] =>
        ((x, y) -> y ./ x)
        => "[4]:1.0_ratio",
        ["Int64[]:0.0", "[4, 3]:0.5"] =>
        ((x, y) -> y ./ x)
        => "[4, 3]:0.5_ratio",
        ["Int64[]:0.0", "[4, 3]:1.0"] =>
        ((x, y) -> y ./ x)
        => "[4, 3]:1.0_ratio",
    )

n_range = root_node_gap_df[!,:n]
labels = [
    "No minors", 
    L"$\mathcal{M}_4$", 
    L"$\mathcal{M}_4$ and $\mathcal{M}_3$ (half)", 
    L"$\mathcal{M}_4$ and $\mathcal{M}_3$", 
]
ctg = CategoricalArray(
    repeat(
        labels, 
        inner = length(n_range)
    )
)
levels!(ctg, labels)
groupedbar(
    repeat(lpad.(string.(n_range), 3), outer = 4),
    Matrix(
        root_node_gap_df |> 
            x -> select(
                x, 
                ["Int64[]:0.0", "[4]:1.0", "[4, 3]:0.5", "[4, 3]:1.0"],
            )
    ),
    group = ctg,
    xlabel = L"Size ($n$)",
    ylim = (10.0^-6, 10.0^0),
    yticks = 10.0.^(-6:1:0),
    yscale = :log10,
    ylabel = "Relative gap, log",
)
Plots.plot!(
    xtickfontsize = 10,
    ytickfontsize = 10,
    xlabelfontsize = 12,
    ylabelfontsize = 12,
    legendfontsize = 10,
)
savefig("postprocessing/plots/mc1_root_loglb_smalllarge_80.0.pdf")

groupedbar(
    repeat(lpad.(string.(n_range), 3), outer = 4),
    Matrix(
        solve_time_df |> 
            x -> select(
                x, 
                ["Int64[]:0.0", "[4]:1.0", "[4, 3]:0.5", "[4, 3]:1.0"],
            )
    ),
    group = ctg,
    legend = :topleft,
    xlabel = L"Size ($n$)",
    ylim = (10.0^-2, 10.0^4),
    yticks = 10.0.^(-2:1:4),
    yscale = :log10,
    ylabel = "Time (s), log",
)
Plots.plot!(
    xtickfontsize = 10,
    ytickfontsize = 10,
    xlabelfontsize = 12,
    ylabelfontsize = 12,
    legendfontsize = 10,
)
savefig("$(@__DIR__)/plots/mc1_root_time_smalllarge_80.0.pdf")
    

# Make plots
p_range = sort(unique(combine_df[!, :p]))
n_range = sort(unique(combine_df[!, :n]))
color_dict = Dict(
    n => c
    for (n, c) in zip(
        n_range, 
        get(ColorSchemes.viridis, collect(0:1:(length(n_range)-1)) ./(length(n_range)-1))
    )
)
shape_dict = Dict(
    2.0 => :circle,
    3.0 => :dtriangle,
)
γ = 80.0
Shor_valid_inequalities_noisy_rank1_num_entries_present = "[4, 3]"
Plots.plot(
    xaxis=:log10, xlim=(10^(-2.0),10^(4.0)),
    yaxis=:log10, ylim=(10^(-7.5),10^(-0.5)),
    yticks = 10 .^ (-7.0:-1.0),
    fmt=:png,
    ylabel="Relative gap", 
    xlabel="Runtime (s)",
)
for p in p_range
    for (i, n) in enumerate(n_range)
        labelled = false
        t = filter(
            r -> (
                r.p == p 
                && r.n == n 
                && r.γ == γ
                && r.Shor_valid_inequalities_noisy_rank1_num_entries_present == Shor_valid_inequalities_noisy_rank1_num_entries_present
            ),
            combine_df,
        )
        if nrow(t) == 0
            continue
        end
        if !labelled
            Plots.plot!(
                t[!,:solve_time_relaxation_geomean],
                t[!,:relative_gap_root_node_geomean],
                label = "p = $(p), n = $(n)",
                color = color_dict[n],
                shape = shape_dict[p],
                lw = 1.3,
            )
            labelled = true
        else
            Plots.plot!(
                t[!,:solve_time_relaxation_geomean],
                t[!,:relative_gap_root_node_geomean],
                # label = "p = $(p), n = $(n)",
                label = "",
                color = color_dict[n],
                shape = shape_dict[p],
                lw = 1.3,
            )
        end
        Plots.annotate!(
            collect(zip(
                t[!, :solve_time_relaxation_geomean] * 1.4,
                t[!, :relative_gap_root_node_geomean] * 1.1,
                [(p != ("Int64[]", 0.0) ? Plots.text("$(p[2])", 9, :left) : "") for p in collect(zip(eachcol(t[!, [:Shor_valid_inequalities_noisy_rank1_num_entries_present, :add_Shor_valid_inequalities_fraction]])...))]
            ))
        )
    end
end
Plots.plot!(legend = :bottomleft, legend_font_pointsize = 8)
Plots.plot!(
    xtickfontsize = 10,
    ytickfontsize = 10,
    xlabelfontsize = 12,
    ylabelfontsize = 12,
    legendfontsize = 10,
)
savefig("postprocessing/plots/mc1_root_lb_time_smalllarge_$(γ)_$(Shor_valid_inequalities_noisy_rank1_num_entries_present).pdf")