include("../../../mpco/test_matrix_completion_disjunctivecuts.jl")

using .TestMatrixCompletionDisjunctiveCuts
using .TestMatrixCompletionNonDisjunctiveCuts
using StatsBase
using Suppressor
using CSV
using DataFrames

# simple test case to quickly compile 
r = @suppress test_matrix_completion_disjunctivecuts(
    1, 10, 10, 30, 0, 0.01, 20.0;
    node_selection = "bestfirst",
    disjunctive_cuts_type = "linear",
    disjunctive_cuts_breakpoints = "smallest_1_eigvec",
    add_Shor_valid_inequalities = false,
    time_limit = 30,
    with_log = false,
)
r = @suppress test_matrix_completion_nondisjunctivecuts(
    1, 10, 10, 30, 0, 0.01, 20.0;
    node_selection = "bestfirst",
    time_limit = 30,
    with_log = false,
)
println("Compilation complete.")

args_df = DataFrame(CSV.File("$(@__DIR__)/args.csv"))

task_index = parse(Int, ARGS[1]) + 1
n_tasks = parse(Int, ARGS[2])
time_limit = nothing # CHANGE

for row_index in task_index:n_tasks:size(args_df, 1)

    # Get paramters from args_df at row row_index
    k = args_df[row_index, :k]
    n = args_df[row_index, :n]
    p = args_df[row_index, :p]
    seed = args_df[row_index, :seed]
    noise = args_df[row_index, :noise]
    γ = args_df[row_index, :γ]
    use_disjunctive_cuts = args_df[row_index, :use_disjunctive_cuts]
    node_selection = convert(
        String,
        args_df[row_index, :node_selection],
    )
    altmin_flag = args_df[row_index, :altmin_flag]

    num_indices = Int(round(p * n * log10(n)))
    local time_limit = Int(2 * n * n)

    if !((n + n) * k ≤ num_indices ≤ n * n)
        continue
    end

    if use_disjunctive_cuts
        result = @timed @suppress test_matrix_completion_disjunctivecuts(
            k, n, n, num_indices, seed, noise, γ;
            node_selection = node_selection,
            disjunctive_cuts_type = "linear",
            disjunctive_cuts_breakpoints = "smallest_1_eigvec",
            add_Shor_valid_inequalities = false,
            time_limit = time_limit,
            root_only = false,
            with_log = false,
            altmin_flag = altmin_flag,
        )
        local r = result.value
    else
        result = @timed @suppress test_matrix_completion_nondisjunctivecuts(
            k, n, n, num_indices, seed, noise, γ;
            node_selection = node_selection,
            time_limit = time_limit, 
            root_only = false,
            with_log = false,
            altmin_flag = altmin_flag,
        )
        local r = result.value
    end

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
            node_selection = node_selection,
            bestfirst_depthfirst_cutoff = r[3]["run_details"]["bestfirst_depthfirst_cutoff"],
            optimality_gap = r[3]["run_details"]["optimality_gap"],
            root_only = false,
            altmin_flag = altmin_flag,
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
            use_disjunctive_cuts = use_disjunctive_cuts,
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
            branching_region = (
                isnothing(r[3]["run_details"]["branching_region"]) ?
                missing : r[3]["run_details"]["branching_region"]
            ), 
            branching_type = (
                isnothing(r[3]["run_details"]["branching_type"]) ?
                missing : r[3]["run_details"]["branching_type"]
            ),
            branch_point = (
                isnothing(r[3]["run_details"]["branch_point"]) ?
                missing : r[3]["run_details"]["branch_point"]
            ),
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
    CSV.write("$(@__DIR__)/records/$(row_index).csv", DataFrame(records))
end