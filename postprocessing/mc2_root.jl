using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using ColorSchemes
using LaTeXStrings

include("../utils.jl")

results_filepath = "mc2_root/01/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :γ,
    :add_Shor_valid_inequalities,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
])
CSV.write(results_filepath, results_df)

# Shor minors added at root node
gdf = groupby(
    results_df,
    [
        :k, :n, :p, :γ, 
        :add_Shor_valid_inequalities,
        :Shor_valid_inequalities_noisy_rank1_num_entries_present,
    ]
)
combine_df = combine(
    gdf, 
    :solve_time_relaxation => geomean, 
    :relative_gap_root_node => geomean,
)

root_node_gap_df = combine_df |> 
    x -> unstack(
        x,
        [:n, :p, :γ], 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :relative_gap_root_node_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:n, :p, :γ],
    ) |>
    x -> select!(
        x,
        :n,
        :p, 
        :γ,
        "Int64[]" => (x -> round.(x, sigdigits = 3)) => "Int64[]",
        "[4]" => (x -> round.(x, sigdigits = 3)) => "[4]",
        "[4, 3]" => (x -> round.(x, sigdigits = 3)) => "[4, 3]",
    )
CSV.write("postprocessing/tables/mc2_root_summary_root_node_gap.csv", root_node_gap_df)

solve_time_df = combine_df |> 
    x -> unstack(
        x,
        [:n, :p, :γ], 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :solve_time_relaxation_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:n, :p, :γ], 
    ) |>
    x -> select!(
        x,
        :n,
        :p, 
        :γ,
        "Int64[]" => (x -> round.(x, sigdigits = 3)) => "Int64[]",
        "[4]" => (x -> round.(x, sigdigits = 3)) => "[4]",
        "[4, 3]" => (x -> round.(x, sigdigits = 3)) => "[4, 3]",
    )
CSV.write("postprocessing/tables/mc2_root_summary_solve_time.csv", solve_time_df)


# Make plots
params = ["Int64[]", "[4]", "[4, 3]"]
p_range = [2.0, 3.0]
n_range = [10, 20, 30]
shape_dict = Dict(
    2.0 => :circle,
    3.0 => :square,
)
color_dict = Dict(
    n => c 
    for (n, c) in zip(
        n_range,
        ColorSchemes.tol_bright.colors
    )
)
for γ in [20.0, 80.0]
    Plots.plot(
        xaxis=:log10, 
        xlim=(10^(-2.0),10^(4.0)),
        yaxis=:log10, 
        ylim=(10^(-6.5),10^(-0.5)),
        fmt=:png,
        ylabel="Relative gap", xlabel="Runtime (s)",
    )
    for p in p_range
        for n in n_range
            t = filter(
                r -> (r.p == p && r.n == n && r.γ == γ),
                combine_df,
            )
            Plots.plot!(
                t[[1,3,2],:solve_time_relaxation_geomean],
                t[[1,3,2],:relative_gap_root_node_geomean],
                label = "p = $(p), n = $(n)",
                color = color_dict[n],
                shape = shape_dict[p],
                yticks = 10 .^ (-6.0:-1.0),
                tickfontsize = 10,
            )
            Plots.annotate!(
                collect(zip(
                    t[[1,3,2],:solve_time_relaxation_geomean] * 1.5,
                    t[[1,3,2],:relative_gap_root_node_geomean] * 1.2,
                    [(p != "Int64[]" ? Plots.text(p, 9, :bottom) : "") for p in params]
                ))
            )
        end
    end
    Plots.plot!(legend = :bottomleft, legend_font_pointsize = 10)
    savefig("postprocessing/plots/mc2_root_lb_time_small_$(γ).pdf")
end