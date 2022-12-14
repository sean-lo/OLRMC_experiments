using CSV
using Glob
using DataFrames
# using Plots
using StatsBase
# using StatsPlots
using CairoMakie

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, 
    :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,
])
CSV.write(results_filepath, results_df)

results_df

lb_proportion_df = deepcopy(results_df)
transform!(
    lb_proportion_df,
    :lower_bound => (
        x -> x ./ select(
            first, 
            groupby(
                lb_proportion_df, 
                [:k, :n, :p, :seed],
            )
        )[!,:lower_bound]
    ) => :lower_bound_ratio,
)
gdf = groupby(
    lb_proportion_df, 
    [:k, :n, :p, :presolve, 
    :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities
    ]
)
combine_df = combine(
    gdf, 
    [:n, :entries_presolved] => ((x, y) -> sum(y .== x .* x)/20) => :proportion_presolved,
    :solve_time_relaxation => mean,
    :lower_bound_ratio => geomean,
)
CSV.write("$(@__DIR__)/summary.csv", combine_df)


for g in groupby(combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :proportion_presolved))
end

for g in groupby(combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :solve_time_relaxation_mean))
end

for g in groupby(combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :lower_bound_ratio_geomean))
end

# Plot heatmap of 
p_range = unique(results_df[:,:p])
n_range = unique(results_df[:,:n])
groups = groupby(combine_df,
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
titles = ["Nothing", "With presolve", "With linear valid inequalities", "With Shor inequalities"]

cmax = maximum(combine_df[!,:lower_bound_ratio_geomean])
cmin = minimum(combine_df[!,:lower_bound_ratio_geomean])
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
            :p, :n, :lower_bound_ratio_geomean,
        )[1:end,2:end]
    )
    heatmap!(
        ax,
        p_range,
        n_range,
        mat, 
        colorrange = (cmin, cmax),
    )
    for i in 1:length(p_range), j in 1:length(n_range)
        textcolor = mat[i, j] < 1.5 ? :white : :black
        text!(
            ax, "$(round(mat[i,j], digits = 2))",
            position = (p_range[i], n_range[j]),
            color = textcolor, 
            align = (:center, :center),
            fontsize = 10,
        )
    end
end
Colorbar(grid[:,end+1], colorrange = (cmin, cmax))
colgap!(grid, 15)
save("$(@__DIR__)/plots/lower_bounds.pdf", fig)