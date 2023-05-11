include("../../MCBnB/src/test_matrix_completion_disjunctivecuts.jl")
include("../utils.jl")

using .TestMatrixCompletionDisjunctiveCuts
using StatsBase
using Suppressor
using CSV
using DataFrames

# simple test case to quickly compile 
r = @suppress test_matrix_completion_disjunctivecuts(
    5, 20, 20, 360, 0, 0.01, 20.0;
    node_selection = "bestfirst",
    disjunctive_cuts_type = "linear",
    disjunctive_cuts_breakpoints = "smallest_1_eigvec",
    add_Shor_valid_inequalities = false,
    time_limit = 60,
    with_log = false,
)
r = @suppress test_matrix_completion_disjunctivecuts(
    5, 20, 20, 200, 0, 0.01, 20.0;
    node_selection = "bestfirst",
    disjunctive_cuts_type = "linear",
    disjunctive_cuts_breakpoints = "smallest_1_eigvec",
    add_Shor_valid_inequalities = false,
    time_limit = 60,
    with_log = false,
)
println("Compilation complete.")

args_df = DataFrame(CSV.File("$(@__DIR__)/args.csv"))

task_index = parse(Int, ARGS[1]) + 1
n_tasks = parse(Int, ARGS[2])
println("Processing rows: $(collect(task_index:n_tasks:size(args_df, 1)))")

for row_index in task_index:n_tasks:size(args_df, 1)

    # Get paramters from args_df at row row_index
    k = args_df[row_index, :k]
    n = args_df[row_index, :n]
    p = args_df[row_index, :p]
    seed = args_df[row_index, :seed]
    noise = args_df[row_index, :noise]
    γ = args_df[row_index, :γ]
    kind = args_df[row_index, :kind]

    num_indices = string_to_num_indices(p, k, n, kind)
    local time_limit = 3600

    if !((n + n) * k ≤ num_indices ≤ n * n)
        continue
    end

    try
        result = @timed @suppress test_matrix_completion_disjunctivecuts(
            k, n, n, num_indices, seed, noise, γ;
            node_selection = "bestfirst",
            disjunctive_cuts_type = "linear",
            disjunctive_cuts_breakpoints = "smallest_1_eigvec",
            time_limit = time_limit,
            root_only = false,
            with_log = false,
            altmin_flag = true,
            use_max_steps = false,
        )
        local r = result.value
        
        lower_bound_root_node = r[3]["run_log"][1,:lower]
        upper_bound_root_node = r[3]["run_log"][1,:upper]
        relative_gap_root_node = r[3]["run_log"][1,:gap]
        lower_bound = r[3]["run_log"][end,:lower]
        upper_bound = r[3]["run_log"][end,:upper]
        relative_gap = r[3]["run_log"][end,:gap]

        records = [
            (
                seed = seed,
                # Parameters
                k = k,
                m = n,
                n = n,
                p = p,
                num_indices = num_indices,
                noise = noise,
                γ = γ,
                λ = r[3]["run_details"]["λ"],
                node_selection = "bestfirst",
                bestfirst_depthfirst_cutoff = r[3]["run_details"]["bestfirst_depthfirst_cutoff"],
                optimality_gap = r[3]["run_details"]["optimality_gap"],
                root_only = false,
                altmin_flag = true,
                max_altmin_probability = (
                    isnothing(r[3]["run_details"]["max_altmin_probability"]) ?
                    missing : r[3]["run_details"]["max_altmin_probability"]
                ),
                min_altmin_probability = (
                    isnothing(r[3]["run_details"]["min_altmin_probability"]) ?
                    missing : r[3]["run_details"]["min_altmin_probability"]
                ),
                altmin_probability_decay_rate = (
                    isnothing(r[3]["run_details"]["altmin_probability_decay_rate"]) ?
                    missing : r[3]["run_details"]["altmin_probability_decay_rate"]
                ),
                use_max_steps = false,
                max_steps = missing,
                time_limit = time_limit,
                use_disjunctive_cuts = true,
                disjunctive_cuts_type = (
                    isnothing(r[3]["run_details"]["disjunctive_cuts_type"]) ?
                    missing : r[3]["run_details"]["disjunctive_cuts_type"]
                ),
                disjunctive_cuts_breakpoints = (
                    isnothing(r[3]["run_details"]["disjunctive_cuts_breakpoints"]) ?
                    missing : r[3]["run_details"]["disjunctive_cuts_breakpoints"]
                ),
                disjunctive_sorting = false,
                presolve = missing,
                add_basis_pursuit_valid_inequalities = missing,
                add_Shor_valid_inequalities = false,
                add_Shor_valid_inequalities_fraction = missing,
                add_Shor_valid_inequalities_iterative = missing,
                max_update_Shor_indices_probability = missing,
                min_update_Shor_indices_probability = missing,
                update_Shor_indices_probability_decay_rate = missing,
                update_Shor_indices_n_minors = missing,
                Shor_valid_inequalities_noisy_rank1_num_entries_present = missing,
                branching_region = missing,
                branching_type = missing,
                branch_point = missing,
                # Results: presolve
                time_taken = r[3]["run_details"]["time_taken"],
                entries_presolved = r[3]["run_details"]["entries_presolved"],
                # Results: time
                solve_time_altmin = r[3]["run_details"]["solve_time_altmin"],
                average_solve_times_altmin = StatsBase.mean(
                    r[3]["run_details"]["dict_solve_times_altmin"][!,:solve_time]
                ),
                average_num_iterations_altmin = StatsBase.mean(
                    r[3]["run_details"]["dict_num_iterations_altmin"][!,:n_iters]
                ),
                solve_time_relaxation_feasibility = r[3]["run_details"]["solve_time_relaxation_feasibility"],
                solve_time_relaxation = r[3]["run_details"]["solve_time_relaxation"],
                average_solve_time_relaxation = StatsBase.mean(
                    r[3]["run_details"]["dict_solve_times_relaxation"][!,:solve_time]
                ),
                # results: nodes
                nodes_explored = r[3]["run_details"]["nodes_explored"],
                nodes_total = r[3]["run_details"]["nodes_total"],
                nodes_dominated = r[3]["run_details"]["nodes_dominated"],
                nodes_relax_infeasible = r[3]["run_details"]["nodes_relax_infeasible"],
                nodes_relax_feasible = r[3]["run_details"]["nodes_relax_feasible"],
                nodes_relax_feasible_pruned = r[3]["run_details"]["nodes_relax_feasible_pruned"],
                nodes_master_feasible = r[3]["run_details"]["nodes_master_feasible"],
                nodes_master_feasible_improvement = r[3]["run_details"]["nodes_master_feasible_improvement"],
                nodes_relax_feasible_split = r[3]["run_details"]["nodes_relax_feasible_split"],
                nodes_relax_feasible_split_altmin = r[3]["run_details"]["nodes_relax_feasible_split_altmin"],
                nodes_relax_feasible_split_altmin_improvement = r[3]["run_details"]["nodes_relax_feasible_split_altmin_improvement"],
                # Results: bound gap
                lower_bound_root_node = lower_bound_root_node,
                upper_bound_root_node = upper_bound_root_node,
                relative_gap_root_node = relative_gap_root_node,
                lower_bound = lower_bound,
                upper_bound = upper_bound,
                relative_gap = relative_gap,
                # Results: MSE
                MSE_in_initial = r[1]["MSE_in_initial"],
                MSE_out_initial = r[1]["MSE_out_initial"],
                MSE_all_initial = r[1]["MSE_all_initial"],
                MSE_in = r[1]["MSE_in"],
                MSE_out = r[1]["MSE_out"],
                MSE_all = r[1]["MSE_all"],
                # Results: Memory
                memory = result.bytes,
            )
        ]
        result = nothing
        CSV.write("$(@__DIR__)/records/$(row_index).csv", DataFrame(records))
    catch
        nothing
    end
end