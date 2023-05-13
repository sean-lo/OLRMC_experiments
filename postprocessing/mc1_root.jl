using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie
using ColorSchemes

results_df = vcat(
    CSV.read("mc1_root/01/combined.csv", DataFrame),
    CSV.read("mc1_root/02/combined.csv", DataFrame) |>
        x -> select(x, Not(:memory)),
)
sort!(results_df, [
    :k, :n, :p, :seed, :γ,
    :add_Shor_valid_inequalities,
    :add_Shor_valid_inequalities_iterative,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
])

filtered_results_df = deepcopy(results_df)
filter!(
    r -> (
        r.add_Shor_valid_inequalities_iterative
        || !(r.Shor_valid_inequalities_noisy_rank1_num_entries_present in ["[4, 3, 2]", "[4, 3, 2, 1]"])
    ), 
    filtered_results_df
)[:,[
    :k, :n, :p, :seed, :γ,
    :add_Shor_valid_inequalities,
    :add_Shor_valid_inequalities_iterative,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
]]

# Shor minors added at root node
gdf = groupby(
    filter(
        r -> (
            !r.add_Shor_valid_inequalities_iterative
        ),
        filtered_results_df
    ),
    [:n, :p, :γ, 
    :add_Shor_valid_inequalities,
    :add_Shor_valid_inequalities_iterative,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,]
)
combine_df = combine(
    gdf, 
    :solve_time_relaxation => geomean, 
    :relative_gap_root_node => (x -> geomean(abs.(x))) => :relative_gap_root_node_geomean,
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
CSV.write("postprocessing/tables/mc1_root_summary_root_node_gap.csv", root_node_gap_df)

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
CSV.write("postprocessing/tables/mc1_root_summary_solve_time.csv", solve_time_df)


# Make plots
params = ["Int64[]", "[4]", "[4, 3]"]
p_range = unique(solve_time_df[:, :p])
full_n_range = unique(solve_time_df[:, :n])
small_n_range = [10, 20, 30]
large_n_range = [50, 75, 100]
shape_dict = Dict(
    2.0 => :circle,
    3.0 => :dtriangle,
)
small_color_dict = Dict(
    n => c 
    for (n, c) in zip(
        small_n_range,
        ColorSchemes.tol_bright.colors
    )
)
large_color_dict = Dict(
    n => c 
    for (n, c) in zip(
        large_n_range,
        ColorSchemes.tol_bright.colors
    )
)
full_color_dict = Dict(
    n => c 
    for (n, c) in zip(
        full_n_range,
        get(ColorSchemes.viridis, collect(0:1:(length(n_range)-1)) ./(length(n_range)-1))
    )
)

for (n_range, color_dict, name) in zip(
    [small_n_range, large_n_range, full_n_range],
    [small_color_dict, large_color_dict, full_color_dict],
    ["small", "large", "all"],
)
    for γ in [20.0, 80.0]
        Plots.plot(
            size = (750, 500),
            xaxis=:log10, xlim=(10^(-2.0),10^(4.0)),
            yaxis=:log10, ylim=(10^(-7.0),10^(-0.5)),
            yticks = 10 .^ (-6.0:-1.0),
            fmt=:png,
            ylabel="Relative gap", 
            xlabel="Runtime (s)",
        )
        for p in p_range
            for n in n_range
                solve_time = collect(skipmissing(collect(filter(
                    r -> (r.p == p && r.n == n && r.γ == γ),
                    solve_time_df,
                )[1, params])))
                relative_gap_root_node = collect(skipmissing(collect(filter(
                    r -> (r.p == p && r.n == n && r.γ == γ),
                    root_node_gap_df,
                )[1, params])))
                Plots.plot!(
                    solve_time,
                    relative_gap_root_node,
                    label = "p = $(p), n = $(n)",
                    color = color_dict[n],
                    shape = shape_dict[p],
                    lw = 2,
                )
                Plots.annotate!(
                    collect(zip(
                        solve_time * 1.5,
                        relative_gap_root_node * 1.2,
                        [(p != "Int64[]" ? Plots.text(p, 9, :bottom) : "") for p in params]
                    ))
                )
            end
        end
        Plots.plot!(legend = :outerright)
        Plots.plot!(
            xtickfontsize = 10,
            ytickfontsize = 10,
            xlabelfontsize = 12,
            ylabelfontsize = 12,
            legendfontsize = 10,
        )
        savefig("postprocessing/plots/mc1_root_lb_time_$(name)_$(γ).pdf")
    end
end