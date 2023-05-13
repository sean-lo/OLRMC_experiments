using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using DelimitedFiles
using LaTeXStrings
using ColorSchemes
using CairoMakie

results_df = vcat(
    [
        CSV.read(filepath, DataFrame)
        for filepath in glob("bp2_root_new/01/combined_*.csv")
    ]...
)
unique!(results_df, [
    :k, :n, :p, :num_indices, :seed, 
    :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,
    :root_only,
]) 
sort!(results_df, [
    :k, :n, :p, :num_indices, :seed, 
    :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,
    :root_only,
])

filtered_results_pknlog_df = deepcopy(results_df)
filter!(
    r -> (r.num_indices == Int(ceil(r.p * r.k * r.n * log10(r.n)))),
    filtered_results_pknlog_df
)

for g in groupby(
    filtered_results_pknlog_df,
    [:k, :n, :p, :num_indices, :seed]
)
    ubdf = filter(
        r -> !r.root_only,
        g,
    )
    if nrow(ubdf) > 0
        ub = ubdf[1, :upper_bound]
        g[!, :true_optimality_gap] = abs.((ub .- g[!, :lower_bound]) ./ g[!, :lower_bound])
    else
        g[!, :true_optimality_gap] .= missing
    end
end

filter!(
    r -> r.root_only, 
    filtered_results_pknlog_df,
)
pknlog_gdf = groupby(
    filtered_results_pknlog_df,
    [:k, :n, :p, :num_indices, :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,]
)
transform!(pknlog_gdf, nrow)
pknlog_combine_df = combine(
    pknlog_gdf,
    nrow,
    [:n, :entries_presolved, :nrow] => ((x, y, z) -> sum(y .== x .* x) / z[1]) => :proportion_presolved,
    :solve_time_relaxation => mean ∘ skipmissing => :solve_time_relaxation_mean,
    :solve_time_relaxation => geomean ∘ skipmissing => :solve_time_relaxation_geomean,
    :time_taken => mean ∘ skipmissing => :time_taken_mean,
    :time_taken => geomean ∘ skipmissing => :time_taken_geomean,
    :true_optimality_gap => mean ∘ skipmissing => :true_optimality_gap_mean,
    :true_optimality_gap => geomean ∘ skipmissing => :true_optimality_gap_geomean,
)
CSV.write("postprocessing/tables/bp2_root_small_pknlog_summary.csv", pknlog_combine_df)

for g in groupby(
    pknlog_combine_df, 
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
    println(unstack(g, :n, :p, :nrow))
end

for g in groupby(
    pknlog_combine_df, 
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
    println(unstack(g, :n, :p, :proportion_presolved))
end

for g in groupby(pknlog_combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :solve_time_relaxation_mean))
end

for g in groupby(pknlog_combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :true_optimality_gap_geomean))
end

# Plot heatmap of 
p_range = unique(results_df[:,:p])
n_range = unique(results_df[:,:n])
groups = groupby(pknlog_combine_df,
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
titles = ["Nothing", "With presolve", "With linear valid inequalities", "With Shor inequalities"]

pknlog_combine_df[!,:true_optimality_gap_geomean]

cmax = maximum(pknlog_combine_df[!,:true_optimality_gap_geomean])
cmin = minimum(pknlog_combine_df[!,:true_optimality_gap_geomean])
fig = Figure(resolution = (1200, 400), fontsize = 18)
grid = fig[1,1] = GridLayout()
for (ind, g) in enumerate(groups)
    ax = Axis(
        grid[1,ind],
        xlabel = L"p",
        ylabel = L"n",
        title = titles[ind],
    )
    ax.xticks = p_range
    ax.yticks = n_range
    mat = Matrix(
        unstack(
            g,
            :p, :n, :true_optimality_gap_geomean,
        )[1:end,2:end]
    )
    CairoMakie.heatmap!(
        ax,
        p_range,
        n_range,
        mat, 
        colorrange = (cmin, cmax),
        colorscale = log10,
    )
    for i in 1:length(p_range), j in 1:length(n_range)
        textcolor = mat[i, j] < 30000 ? :white : :black
        text!(
            ax, "$(round(mat[i,j], digits = 2))",
            position = (p_range[i], n_range[j]),
            color = textcolor, 
            align = (:center, :center),
            fontsize = 15,
        )
    end
end
Colorbar(grid[:,end+1], colorrange = (cmin, cmax))
colgap!(grid, 15)
save("postprocessing/plots/bp2_root_small_pknlog_optimality_gap_geomean.pdf", fig)