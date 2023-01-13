using CSV
using Glob
using DataFrames
using StatsBase
using CairoMakie
using DelimitedFiles

results_filepath = "$(@__DIR__)/combined.csv"
results_df = CSV.read(results_filepath, DataFrame)
sort!(results_df, [
    :k, :n, :p, :seed, 
    :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,
    :root_only,
]) 
CSV.write(results_filepath, results_df)

filtered_results_df = deepcopy(results_df)
filter!(
    r -> (r.num_indices == Int(ceil(r.p * r.k * r.n * log10(r.n)))),
    filtered_results_df
)
filtered_results_df[!, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]]
lb_proportion_df = deepcopy(filtered_results_df)

for g in groupby(
    lb_proportion_df,
    [:k, :n, :p, :num_indices, :seed]
)
    ubdf = filter(
        r -> !r.root_only,
        g
    )
    ub = (nrow(ubdf) ≥ 1 ? ubdf[1,:upper_bound] : 0.0)
    g[!,:true_optimality_gap] = abs.((ub .- g[!,:lower_bound]) ./ g[!,:lower_bound])
end
lb_proportion_df[!, :true_optimality_gap]
filter!(
    r -> r.root_only, 
    lb_proportion_df,
)
gdf = groupby(
    lb_proportion_df,
    [:k, :n, :p, :num_indices, :presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities,]
)
transform!(gdf, nrow)
combine_df = combine(
    gdf, 
    [:n, :entries_presolved, :nrow] => ((x, y, z) -> sum(y .== x .* x) / 20) => :proportion_presolved,
    :solve_time_relaxation => mean,
    :true_optimality_gap => geomean,
)
CSV.write("$(@__DIR__)/summary.csv", combine_df)

combine_df
# FIXME: change later
combine_df[isnan.(combine_df.true_optimality_gap_geomean), :true_optimality_gap_geomean] .= 0.0
combine_df[combine_df.n .== 10, :proportion_presolved] ./= 2
combine_df[isinf.(combine_df.true_optimality_gap_geomean), :true_optimality_gap_geomean] .= 1.0

groupby(
    combine_df, 
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)

for g in groupby(
    combine_df, 
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
    println(unstack(g, :n, :p, :proportion_presolved))
end

for g in groupby(combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :solve_time_relaxation_mean))
end

for g in groupby(combine_df, [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities])
    println(unstack(g, :n, :p, :true_optimality_gap_geomean))
end

combine_df

# Plot heatmap of 
p_range = unique(results_df[:,:p])
n_range = unique(results_df[:,:n])
groups = groupby(combine_df,
    [:presolve, :add_basis_pursuit_valid_inequalities, :add_Shor_valid_inequalities]
)
titles = ["Nothing", "With presolve", "With linear valid inequalities", "With Shor inequalities"]

cmax = maximum(combine_df[!,:true_optimality_gap_geomean])
cmin = minimum(combine_df[!,:true_optimality_gap_geomean])
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
save("$(@__DIR__)/plots/_lower_bounds.pdf", fig)