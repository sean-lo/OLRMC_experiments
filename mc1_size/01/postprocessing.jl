using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using DelimitedFiles

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :n, :p, :seed,
])
CSV.write(results_filepath, results_df)

println(names(results_df))

gdf = groupby(
    results_df,
    [:n, :p, :num_indices],
)
combine_df = combine(
    gdf, 
    :nodes_explored => mean,
    :average_solve_time_relaxation => mean => :solve_time_relaxation_mean,
    :time_taken => geomean,
    :relative_gap_root_node => (x -> geomean(abs.(x))) => :relative_gap_root_node_geomean,
    :relative_gap => (x -> geomean(abs.(x))) => :relative_gap_geomean,
)
sort!(
    combine_df, 
    [
        :n, :p, :num_indices,
    ]
)
CSV.write("$(@__DIR__)/summary.csv", combine_df)

# pkn
combine_df[1:2:nrow(combine_df),:]
# pkn log10(n)
combine_df[2:2:nrow(combine_df),:]

p = 3.0
pl = Plots.plot(
    xscale = :log10,
    xrange = (10.0^-6, 10.0^0),
    xticks = 10.0 .^ (-6:1:0),
    ylabel = "Empirical CDF",
    xlabel = "Relative gap",
)
colors = Dict(
    50 => :brown,
    75 => :red,
    100 => :orange,
    125 => :green,
    150 => :blue,
)
for n in n_range
    StatsPlots.ecdfplot!(
        filter(
            r -> (
                r.n == n
                && r.p == p
                && r.num_indices == Int(ceil(p * 1 * n))
            ),
            results_df
        )[:,:relative_gap],
        color = colors[n],
        label = "n = $n, " * L"pkn" * " entries",
    )
    StatsPlots.ecdfplot!(
        filter(
            r -> (
                r.n == n
                && r.p == p
                && r.num_indices == Int(ceil(p * 1 * n * log10(n)))
            ),
            results_df
        )[:,:relative_gap],
        color = colors[n],
        style = :dash,
        label = "n = $n, " * L"pkn \ \log_{10}(n)" * " entries",
    )
end
display(pl)
savefig("$(@__DIR__)/plots/ecdf_$p.png")

unstack(
    combine_df,
    :n, :p, :relative_gap_geomean,
)
unstack(
    combine_df,
    :n, :p, :nodes_explored_mean,
)
unstack(
    combine_df,
    :n, :p, :solve_time_relaxation_mean,
)

n_range = [50, 75, 100, 125, 150]
p_range = [2.0, 2.5, 3.0]

pl = Plots.plot(
    yscale = :log,
    yticks = 10.0 .^ (-4:1:0),
    yrange = (10.0^-4, 10.0^0),
    ylabel = "Relative gap",
    xlabel = L"Size ($n$)",
    xticks = n_range,
    legend = :bottomleft,
)
colors = Dict(
    2.0 => :blue,
    2.5 => :green, 
    3.0 => :red,
)
for p in p_range
    Plots.plot!(
        n_range,
        filter(
            r -> (
                r.p == p
                && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
            ), 
            combine_df
        )[:,:relative_gap_geomean],
        label = "p = $p",
        color = colors[p],
        shape = :circle,
        xticks = n_range,
    )
    Plots.plot!(
        n_range,
        filter(
            r -> (
                r.p == p
                && r.num_indices == Int(ceil(r.p * 1 * r.n * log10(r.n)))
            ), 
            combine_df
        )[:,:relative_gap_root_node_geomean],
        label = "p = $p, root node",
        color = colors[p],
        shape = :circle,
        style = :dash,
    )
end
display(pl)
savefig("$(@__DIR__)/plots/mc1_size_log.png")