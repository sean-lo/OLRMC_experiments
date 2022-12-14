using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using CairoMakie

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :γ, :noise,
    :add_Shor_valid_inequalities,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
])
CSV.write(results_filepath, results_df)

gdf = groupby(
    results_df,
    [:k, :n, :p, :γ, :noise,
    :add_Shor_valid_inequalities,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,]
)
combine_df = combine(
    gdf, 
    :solve_time_relaxation => geomean, 
    :relative_gap_root_node 
    => (x -> geomean(abs.(x))) 
    => :relative_gap_root_node_geomean,
)

root_node_gap_df = combine_df |> 
    x -> unstack(
        x,
        [:γ, :n, :noise], 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :relative_gap_root_node_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:γ, :n, :noise],
    )
CSV.write("$(@__DIR__)/summary_root_node_gap.csv", root_node_gap_df)

solve_time_df = combine_df |> 
    x -> unstack(
        x,
        [:γ, :n, :noise],:Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :solve_time_relaxation_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:γ, :n, :noise],
    )
CSV.write("$(@__DIR__)/summary_solve_time.csv", solve_time_df)

# Make plots
params = ["Int64[]", "[4]", "[4, 3]"]
color_dict = Dict(
    50 => :blue,
    75 => :green,
    100 => :red,
)
shape_dict = Dict(
    2.0 => :circle,
    3.0 => :square,
)
p = 2.0
n_range = [50, 75, 100]
for γ in [20.0, 80.0]
    Plots.plot(
        xaxis=:log10, xlim=(10^(-2.0),10^4.0),
        yaxis=:log10, ylim=(10^(-6.5),10^(-0.5)),
        fmt=:png,
        ylabel="Relative gap", xlabel="Runtime (s)",
        title="Rank-1 matrix completion: root node relaxations"
    )
    for n in n_range
        t = filter(
            r -> (r.p == p && r.n == n && r.γ == γ),
            combine_df,
        )
        Plots.plot!(
            t[[1,3,2],:solve_time_relaxation_geomean],
            t[[1,3,2],:relative_gap_root_node_geomean],
            label = "γ = $γ, p = $p, n = $(n)",
            color = color_dict[n],
            shape = shape_dict[p],
            yticks = 10 .^ (-6.0:-1.0),
        )
        Plots.annotate!(
            collect(zip(
                t[[1,3,2],:solve_time_relaxation_geomean],
                t[[1,3,2],:relative_gap_root_node_geomean] * 1.1,
                [(p != "Int64[]" ? Plots.text(p, 8, :bottom) : "") for p in params]
            ))
        )
    end
    Plots.plot!(legend = :bottomleft)
    savefig("$(@__DIR__)/plots/$(γ).png")
end