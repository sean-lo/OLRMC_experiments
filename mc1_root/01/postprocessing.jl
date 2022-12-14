using CSV
using Glob
using DataFrames
using Plots
using StatsBase
using StatsPlots

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, :γ,
    :add_Shor_valid_inequalities,
    :add_Shor_valid_inequalities_iterative,
    :Shor_valid_inequalities_noisy_rank1_num_entries_present,
])
CSV.write(results_filepath, results_df)

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
CSV.write("$(@__DIR__)/filtered.csv", filtered_results_df)

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
select(
    unstack(
        combine_df, [:n, :p, :γ], 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :relative_gap_root_node_geomean
    ),
    Not("[4, 3]"), "[4, 3]",
)

root_node_gap_df = combine_df |> 
    x -> unstack(
        x,
        [:γ, :p, :n], 
        :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :relative_gap_root_node_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:γ, :p, :n],
    )
CSV.write("$(@__DIR__)/summary_root_node_gap.csv", root_node_gap_df)

solve_time_df = combine_df |> 
    x -> unstack(
        x,
        [:γ, :p, :n], :Shor_valid_inequalities_noisy_rank1_num_entries_present, 
        :solve_time_relaxation_geomean,
    ) |> 
    x -> select(
        x, 
        Not("[4, 3]"), "[4, 3]"
    ) |>
    x -> sort(
        x, 
        [:γ, :p, :n],
    )
CSV.write("$(@__DIR__)/summary_solve_time.csv", solve_time_df)


# Make plots
params = ["Int64[]", "[4]", "[4, 3]"]
color_dict = Dict(
    10 => :blue,
    20 => :green,
    30 => :red,
)
shape_dict = Dict(
    2.0 => :circle,
    3.0 => :square,
)
p_range = [2.0, 3.0]
n_range = [10, 20, 30]
for γ in [20.0, 80.0]
    plot(
        xaxis=:log10, xlim=(0.01,100),
        yaxis=:log10, ylim=(10^(-2.5),10^0.5),
        fmt=:png,
        ylabel="Relative gap", xlabel="Runtime (s)",
        title="Rank-1 matrix completion: root node relaxations\n(Shor LMIs added together)"
    )
    for p in p_range
        for n in n_range
            t = filter(
                r -> (r.p == p && r.n == n && r.γ == γ),
                combine_df,
            )
            plot!(
                t[[1,3,2],:solve_time_relaxation_geomean],
                t[[1,3,2],:relative_gap_root_node_geomean],
                label = "γ = $γ, p = $(p), n = $(n)",
                color = color_dict[n],
                shape = shape_dict[p],
            )
            annotate!(
                collect(zip(
                    t[[1,3,2],:solve_time_relaxation_geomean],
                    t[[1,3,2],:relative_gap_root_node_geomean] * 1.1,
                    [text(p, 8, :bottom) for p in params]
                ))
            )
        end
    end
    plot!(legend = :topright)
    savefig("$(γ).png")
end