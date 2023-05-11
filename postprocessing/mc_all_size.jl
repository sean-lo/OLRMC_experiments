using CSV
using Glob
using DataFrames
using StatsBase
using Plots
using CairoMakie
using LaTeXStrings
using ColorSchemes

include("../utils.jl")

all_data = outerjoin(
    [   
        CSV.read("mc1_size/linear/summary.csv", DataFrame),
        CSV.read("mc2_size/summary.csv", DataFrame),
        CSV.read("mc3_size/summary.csv", DataFrame),
        CSV.read("mc4_size/summary.csv", DataFrame),
        CSV.read("mc5_size/summary.csv", DataFrame),
    ]...,
    on = names(CSV.read("mc5_size/summary.csv", DataFrame)),
)

CSV.write("$(@__DIR__)/tables/mc_size.csv", all_data)

show(all_data, allrows = true)

rank_dataframes = Dict()
for var in [
    :relative_gap_root_node_geomean,
    :relative_gap_geomean,
    :MSE_difference,
    :MSE_ratio,
    :MSE_mf_difference,
    :MSE_mf_ratio,
    :MSE_isvd_difference,
    :MSE_isvd_ratio,
]
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for p in [2.0, 2.5, 3.0]

            rank_dataframes[(String(var), indices_string_short, p)] = all_data |>
                x -> filter(
                    r -> (
                        r.p == p
                        && r.num_indices == string_to_num_indices(r.p, r.k, r.n, indices_string)
                    ), 
                    x
                ) |> 
                x -> unstack(
                    x, 
                    :n, :k, var,
                ) |>
                x -> x[completecases(x), :] |>
                disallowmissing!
        end
    end
end

# Optimality gap heatmaps
using CairoMakie
for p in [2.0, 2.5, 3.0]
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        df = rank_dataframes[(String(:relative_gap_root_node_geomean), indices_string_short, p)]
        n_range = vec(df[!, :n])
        k_range = parse.(Int, names(df)[2:end])
        cmax = maximum(Matrix(df[:,2:end]))
        cmin = 0.0
        titles = ["Root node relative gap", "Relative gap"]
        fig = Figure(resolution = (800, 500), fontsize = 18)
        grid = fig[1,1] = GridLayout()
        for (ind, var) in enumerate([
            :relative_gap_root_node_geomean,
            :relative_gap_geomean,
        ])
            df = rank_dataframes[(String(var), indices_string_short, p)]
            ax = Axis(
                grid[1,ind],
                xlabel = L"k",
                ylabel = L"n",
                title = titles[ind],
            )
            ax.xticks = k_range
            ax.yticks = n_range
            ax.xlabelsize = 18
            ax.ylabelsize = 18
            ax.titlesize = 22
            mat = Matrix(df[:,2:end])'
            CairoMakie.heatmap!(
                ax,
                k_range,
                n_range,
                mat, 
                colorrange = (cmin, cmax),
            )
            for i in 1:length(k_range), j in 1:length(n_range)
                textcolor = mat[i,j] < (0.75 * cmax) ? :white : :black
                text!(
                    ax, "$(round(mat[i,j], digits = 2))",
                    position = (k_range[i], n_range[j]),
                    color = textcolor, 
                    align = (:center, :center),
                    fontsize = 18,
                )
            end
        end
        Colorbar(grid[:,end+1], colorrange = (cmin, cmax))
        colgap!(grid, 15)
        save("postprocessing/plots/mc_size_rank_relative_gap_$(indices_string_short)_$(p)_50.pdf", fig)
    end
end

# Optimality gap line plots
for p in [2.0, 2.5, 3.0]
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        df = rank_dataframes[(String(:relative_gap_root_node_geomean), indices_string_short, p)]
        n_range = vec(df[!, :n])
        k_range = parse.(Int, names(df)[2:end])
        colors = Dict(
            k => c
            for (k, c) in zip(
                k_range,
                ColorSchemes.seaborn_colorblind6.colors,
            )
        )
        pl = Plots.plot(
            yscale = :log10,
            ylim = (10.0^(-6), 10.0^(0)),
            yticks = 10.0.^(-6:1:0),
            xticks = n_range,
            legend = :bottomleft,
            ylabel = "Relative gap",
            xlabel = L"Size ($n$)",
        )
        rank_relative_gap_root_node_geomean_df = rank_dataframes[(String(:relative_gap_root_node_geomean), indices_string_short, p)]
        rank_relative_gap_geomean_df = rank_dataframes[(String(:relative_gap_geomean), indices_string_short, p)]
        for k in k_range
            Plots.plot!(
                n_range,
                rank_relative_gap_root_node_geomean_df[!, "$k"],
                label = "k = $k, root node",
                color = colors[k],
                shape = :circle,
                style = :dash,
            )
            Plots.plot!(
                n_range,
                rank_relative_gap_geomean_df[!, "$k"],
                label = "k = $k",
                color = colors[k],
                shape = :circle,
                style = :solid,
            )
        end
        Plots.plot!(
            xtickfontsize = 10,
            ytickfontsize = 10,
            xlabelfontsize = 12,
            ylabelfontsize = 12,
            legendfontsize = 10,
        )
        savefig("postprocessing/plots/mc_size_gap_$(indices_string_short)_linear_$(p)_50.pdf")
    end
end

# MSE difference
for p in [2.0, 2.5, 3.0]
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for (var, title) in zip(
            [
                :MSE_difference,
                :MSE_mf_difference,
                :MSE_isvd_difference,
            ],
            [
                "MSE improvement",
                "MSE improvement over MatrixFactorization()",
                "MSE improvement over IterativeSVD()",
            ]
        )
            df = rank_dataframes[(String(var), indices_string_short, p)]
            n_range = vec(df[!, :n])
            k_range = parse.(Int, names(df)[2:end])
            colors = Dict(
                k => c
                for (k, c) in zip(
                    k_range,
                    ColorSchemes.seaborn_colorblind6.colors,
                )
            )
            shapes = Dict(
                1 => :none,
                2 => :cross,
                3 => :dtriangle,
                4 => :rect,
                5 => :pentagon,
            )
            pl = Plots.plot(
                # yscale = :log10,
                xticks = n_range,
                legend = :topright,
                ylabel = "MSE improvement",
                xlabel = L"Size ($n$)",
                # title = title,
            )
            if var == :MSE_mf_difference
                Plots.plot!(
                    legend = :topleft,
                    ylims = (-0.5, 5.0),
                    yticks = -1.0:1.0:5.0,
                )
            elseif var == :MSE_difference
                if indices_string_short == "pkn"
                    ylims = (-0.1, 0.7)
                elseif indices_string_short == "pknlog"
                    ylims = (-0.05, 0.25)
                elseif indices_string_short == "pkn65log"
                    ylims = (0.0, 0.2)
                end
                Plots.plot!(
                    ylims = ylims,
                )
            end
            for k in k_range
                Plots.plot!(
                    n_range,
                    df[!, "$k"],
                    label = "k = $k",
                    color = colors[k],
                    shape = shapes[k],
                    lw = 2,
                    style = :solid,
                )
            end
            Plots.plot!(
                xtickfontsize = 10,
                ytickfontsize = 10,
                xlabelfontsize = 12,
                ylabelfontsize = 12,
                legendfontsize = 10,
            )
            savefig("postprocessing/plots/mc_size_$(String(var))_$(indices_string_short)_linear_$(p)_50.pdf")
        end
    end
end

# MSE ratio 
for p in [2.0, 2.5, 3.0]
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for (var, title) in zip(
            [
                :MSE_ratio,
                :MSE_mf_ratio,
                :MSE_isvd_ratio,
            ],
            [
                "MSE improvement (%)",
                "MSE improvement (%) over MatrixFactorization()",
                "MSE improvement (%) over IterativeSVD()",
            ]
        )
            df = rank_dataframes[(String(var), indices_string_short, p)]
            n_range = vec(df[!, :n])
            k_range = parse.(Int, names(df)[2:end])
            colors = Dict(
                k => c
                for (k, c) in zip(
                    k_range,
                    ColorSchemes.seaborn_colorblind6.colors,
                )
            )
            shapes = Dict(
                1 => :none,
                2 => :cross,
                3 => :dtriangle,
                4 => :rect,
                5 => :pentagon,
            )
            pl = Plots.plot(
                # yscale = :log10,
                xticks = n_range,
                legend = :topright,
                ylabel = "MSE improvement (%)",
                xlabel = L"Size ($n$)",
            )
            for k in k_range
                Plots.plot!(
                    n_range,
                    100 .* df[!, "$k"],
                    label = "k = $k",
                    color = colors[k],
                    shape = shapes[k],
                    lw = 2,
                    style = :solid,
                )
            end
            Plots.plot!(
                xtickfontsize = 10,
                ytickfontsize = 10,
                xlabelfontsize = 12,
                ylabelfontsize = 12,
                legendfontsize = 10,
            )
            savefig("postprocessing/plots/mc_size_$(String(var))_$(indices_string_short)_linear_$(p)_50.pdf")
        end
    end
end

# For each rank

p_dataframes = Dict()
for k in 1:5
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for var in [
            :relative_gap_root_node_geomean,
            :relative_gap_geomean,
            :MSE_difference,
            :MSE_ratio,
            :MSE_mf_difference,
            :MSE_mf_ratio,
            :MSE_isvd_difference,
            :MSE_isvd_ratio,
        ]
            p_dataframes[(String(var), indices_string_short, k)] = all_data |> 
                x -> filter(
                    r -> (
                        r.k == k
                        && r.num_indices == string_to_num_indices(r.p, r.k, r.n, indices_string)
                    ),
                    x
                ) |>
                x -> unstack(
                    x, 
                    :n, :p, var,
                )
        end
    end
end

p_dataframes[(String(:relative_gap_root_node_geomean), "pkn", 1)]

# Optimality gap
for k in 1:5
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        relative_gap_geomean_df = p_dataframes[(String(:relative_gap_geomean), indices_string_short, k)]
        relative_gap_root_node_geomean_df = p_dataframes[(String(:relative_gap_root_node_geomean), indices_string_short, k)]
        n_range = [10, 20, 30, 40, 50, 75, 100, 125, 150]
        p_range = [2.0, 2.5, 3.0]

        pl = Plots.plot(
            yscale = :log,
            yticks = 10.0 .^ (-6:1:0),
            yrange = (10.0^-6, 10.0^0),
            ylabel = "Relative gap",
            xlabel = L"Size ($n$)",
            xticks = n_range,
            legend = :bottomleft,
        )
        colors = Dict(
            p => c
            for (p, c) in zip(
                p_range,
                ColorSchemes.seaborn_colorblind6.colors,
            )
        )

        for p in p_range
            Plots.plot!(
                n_range,
                relative_gap_geomean_df[!, string(p)],
                label = "p = $p",
                color = colors[p],
                shape = :circle,
                lw = 2,
            )
            Plots.plot!(
                n_range,
                relative_gap_root_node_geomean_df[!, string(p)],
                label = "p = $p, root node",
                color = colors[p],
                shape = :circle,
                lw = 2,
                style = :dash,
            )
        end
        Plots.plot!(
            xtickfontsize = 10,
            ytickfontsize = 10,
            xlabelfontsize = 12,
            ylabelfontsize = 12,
            legendfontsize = 10,
        )
        savefig("postprocessing/plots/mc$(k)_size_gap_$(indices_string_short)_linear_50.pdf")
    end
end

# MSE difference 
for k in 1:5
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for (var, title) in zip(
            [
                :MSE_difference,
                :MSE_mf_difference,
                :MSE_isvd_difference,
            ],
            [
                "MSE improvement",
                "MSE improvement over MatrixFactorization()",
                "MSE improvement over IterativeSVD()",
            ]
        )
            df = p_dataframes[(String(var), indices_string_short, k)]
            n_range = [10, 20, 30, 40, 50, 75, 100, 125, 150]
            p_range = [2.0, 2.5, 3.0]

            colors = Dict(
                p => c
                for (p, c) in zip(
                    p_range,
                    ColorSchemes.seaborn_colorblind6.colors,
                )
            )
            pl = Plots.plot(
                # yrange = (0.0, 0.25),
                # yticks = 0.0:0.05:0.25,
                ylabel = "MSE improvement",
                xlabel = L"Size ($n$)",
                xticks = n_range,
                legend = :topright,
            )
            for p in p_range
                Plots.plot!(
                    n_range, 
                    df[!, "$p"],
                    label = "p = $p",
                    color = colors[p],
                    shape = :circle,
                    lw = 2,
                )
            end
            Plots.plot!(
                xtickfontsize = 10,
                ytickfontsize = 10,
                xlabelfontsize = 12,
                ylabelfontsize = 12,
                legendfontsize = 10,
            )
            savefig("postprocessing/plots/mc$(k)_size_$(String(var))_$(indices_string_short)_linear_50.pdf")
        end
    end
end

# MSE ratio  
for k in 1:5
    for (indices_string, indices_string_short) in [
        ("pkn", "pkn"),
        ("pkn log_{10}(n)", "pknlog"),
        ("pkn^{6/5} log_{10}(n) / 10^{1/5}", "pkn65log"),
    ]
        for (var, title) in zip(
            [
                :MSE_ratio,
                :MSE_mf_ratio,
                :MSE_isvd_ratio,
            ],
            [
                "MSE improvement (%)",
                "MSE improvement (%) over MatrixFactorization()",
                "MSE improvement (%) over IterativeSVD()",
            ]
        )
            df = p_dataframes[(String(var), indices_string_short, k)]
            n_range = [10, 20, 30, 40, 50, 75, 100, 125, 150]
            p_range = [2.0, 2.5, 3.0]

            colors = Dict(
                p => c
                for (p, c) in zip(
                    p_range,
                    ColorSchemes.seaborn_colorblind6.colors,
                )
            )
            pl = Plots.plot(
                # yrange = (0.0, 0.6),
                # yticks = 0.0:0.1:0.6,
                ylabel = "MSE improvement (%)",
                xlabel = L"Size ($n$)",
                xticks = n_range,
                legend = :topright,
            )
            for p in p_range
                Plots.plot!(
                    n_range, 
                    100 .* df[!, "$p"],
                    label = "p = $p",
                    color = colors[p],
                    shape = :circle,
                    lw = 2,
                )
            end
            Plots.plot!(
                xtickfontsize = 10,
                ytickfontsize = 10,
                xlabelfontsize = 12,
                ylabelfontsize = 12,
                legendfontsize = 10,
            )
            savefig("postprocessing/plots/mc$(k)_size_$(String(var))_$(indices_string_short)_linear_50.pdf")
        end
    end
end

kind_dataframes = Dict()
for var in [
    :relative_gap_root_node_geomean,
    :relative_gap_geomean,
    :MSE_difference,
    :MSE_ratio,
    :MSE_mf_difference,
    :MSE_mf_ratio,
    :MSE_isvd_difference,
    :MSE_isvd_ratio,
]
    for k in 1:5
        for p in [2.0, 2.5, 3.0]
            df = all_data |>
                x -> filter(
                    r -> (
                        r.p == p
                        && r.k == k
                    ), 
                    x
                ) |>
                x -> transform(
                    x, 
                    [:p, :k, :n, :num_indices] => 
                    ByRow((p, k, n, num_indices) -> num_indices_to_string(p, k, n, num_indices)) => 
                    :kind
                ) |>
                x -> unstack(
                    x, 
                    :n, :kind, var,
                )

            for row in eachrow(df)
                if row.n == 10
                    if ismissing(row["pkn log_{10}(n)"])
                        row["pkn log_{10}(n)"] = row["pkn"]
                    end
                    if ismissing(row["pkn^{6/5} log_{10}(n) / 10^{1/5}"])
                        row["pkn^{6/5} log_{10}(n) / 10^{1/5}"] = row["pkn"]
                    end
                end
            end
            kind_dataframes[(String(var), k, p)] = df
        end
    end
end

kind_dataframes[("MSE_isvd_ratio", 3, 3.0)]