using CSV
using Glob
using DataFrames
using StatsBase
using LaTeXStrings

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
unique!(results_df, [
    :seed,
    :k, :n, :p, :num_indices,
])
sort!(results_df, [
    :seed,
    :k, :n, :p, :num_indices
])
results_df[:,:entries_presolved_normalized] = results_df[:,:entries_presolved] ./ (results_df[:,:n] .^ 2)
CSV.write(results_filepath, results_df)

k_range = [1, 2]
n_range = [10, 20, 30, 40, 50, 75, 100]
p_range = [2.0, 2.5, 3.0]
kind_range = [
    "pkn", 
    "pkn \\log_{10}(n)",
    "pkn^{6/5} \\log_{10}(n) / 10^{1/5}",
    "pkn^{3/2} / 10^{1/2}",
    "pkn^{2} / 10",
]

gdf = groupby(results_df, [:k, :n, :p, :num_indices])
combine_df = combine(
    gdf, 
    # [:n, :entries_presolved] => ((x, y) -> sum(y .== x .* x)/10000) => :proportion_presolved,
    :entries_presolved_normalized => (x -> sum(x .== 1.0) / 10000) => :proportion_presolved,
    :entries_presolved_normalized => mean,
    :time_taken => mean,
)
CSV.write("$(@__DIR__)/summary.csv", combine_df)


entries_presolved_df = DataFrame(
    "p" => Float64[],
    "k" => Int[],
    "kind" => String[],
    [string(n) => Float64[] 
    for n in n_range]...,
)
for p in p_range, k in k_range, kind in kind_range
    if kind == "pkn"
        entries_presolved = filter(
            r -> (
                r.p == p 
                && r.k == k 
                && r.num_indices == Int(ceil(r.p * r.k * r.n))
            ), combine_df
        )[!, :proportion_presolved]
    elseif kind == "pkn \\log_{10}(n)"
        entries_presolved = filter(
            r -> (
                r.p == p 
                && r.k == k 
                && r.num_indices == Int(ceil(r.p * r.k * r.n * log10(r.n)))
            ), combine_df
        )[!, :proportion_presolved]
    elseif kind == "pkn^{6/5} \\log_{10}(n) / 10^{1/5}"
        entries_presolved = filter(
            r -> (
                r.p == p 
                && r.k == k 
                && r.num_indices == Int(ceil(r.p * r.k * r.n^(1.2) * log10(r.n) / 10^(0.2)))
            ), combine_df
        )[!, :proportion_presolved]
    elseif kind == "pkn^{3/2} / 10^{1/2}"
        entries_presolved = filter(
            r -> (
                r.p == p 
                && r.k == k 
                && r.num_indices == Int(ceil(r.p * r.k * r.n * sqrt(r.n) / sqrt(10)))
            ), combine_df
        )[!, :proportion_presolved]
    elseif kind == "pkn^{2} / 10"
        entries_presolved = filter(
            r -> (
                r.p == p 
                && r.k == k 
                && r.num_indices == Int(ceil(r.p * r.k * r.n * r.n / 10))
            ), combine_df
        )[!, :proportion_presolved]
    end
    push!(entries_presolved_df, 
        vcat(p, k, kind, entries_presolved)
    )
end


using CairoMakie
for p in p_range, k in k_range
    f = Figure()
    ax = Axis(
        f[1,1],
        xlabel = L"$n$",
        ylabel = "Proportion",
    )
    for (i, kind) in enumerate(kind_range)
        scatterlines!(
            ax,
            n_range, 
            collect(
                filter(
                    r -> (r.p == p && r.k == k && r.kind == kind), 
                    entries_presolved_df
                )[1,4:end]
            ), 
            label = latexstring(kind),
        )
    end
    axislegend(position = :rc)
    save("$(@__DIR__)/plots/$(p)_$(k).png", f)
end

using Plots
for p in p_range, k in k_range
    Plots.plot(
        xlabel = L"$n$",
        ylabel = "Proportion",
        legend = :right,
        ylim = (-0.1, 1.1), 
        yticks = 0:0.5:1,
    )
    for (i, kind) in enumerate(kind_range)
        Plots.plot!(
            n_range, 
            collect(
                filter(
                    r -> (r.p == p && r.k == k && r.kind == kind), 
                    entries_presolved_df
                )[1,4:end]
            ), 
            label = latexstring(kind),
            shape = :circle,
        )
    end
    savefig("$(@__DIR__)/plots/_$(p)_$(k).png")
end