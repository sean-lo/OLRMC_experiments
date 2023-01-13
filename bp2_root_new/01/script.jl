include("../../../mpco/test_basis_pursuit_disjunctivecuts.jl")

using .TestBasisPursuitDisjunctiveCuts
using StatsBase
using Suppressor
using CSV
using DataFrames

# simple test case to quickly compile 
r1 = @suppress test_basis_pursuit_disjunctivecuts(
    2, 10, 10, 80, 0;
    node_selection = "bestfirst",
    disjunctive_cuts_type = "linear",
    disjunctive_cuts_breakpoints = "smallest_1_eigvec",
    presolve = true,
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
    kind = args_df[row_index, :kind]
    presolve = Bool(args_df[row_index, :presolve])
    add_Shor_valid_inequalities = Bool(args_df[row_index, :add_Shor_valid_inequalities])
    add_basis_pursuit_valid_inequalities = Bool(args_df[row_index, :add_basis_pursuit_valid_inequalities])
    root_only = Bool(args_df[row_index, :root_only])

    if kind == "pkn"
        num_indices = Int(ceil(p * k * n))
    elseif kind == "pkn log10(n)"
        num_indices = Int(ceil(p * k * n * log10(n)))
    end
    time_limit = 3600

    if !((n + n) * k ≤ num_indices ≤ n * n)
        continue
    end

    try
        result = @timed @suppress test_basis_pursuit_disjunctivecuts(
            k, n, n, num_indices, seed;
            presolve = presolve,
            add_basis_pursuit_valid_inequalities = add_basis_pursuit_valid_inequalities,
            add_Shor_valid_inequalities = add_Shor_valid_inequalities,
            node_selection = "bestfirst",
            disjunctive_cuts_type = "linear",
            disjunctive_cuts_breakpoints = "smallest_1_eigvec",
            time_limit = time_limit,
            root_only = root_only,
            with_log = false,
            use_max_steps = false,
        )
        r = result.value
        if r[3]["run_details"]["entries_presolved"] == n * n
            lower_bound_root_node = r[1]["objective"]
            upper_bound_root_node = r[1]["objective"]
            relative_gap_root_node = 0.0
            lower_bound = r[1]["objective"]
            upper_bound = r[1]["objective"]
            relative_gap = 0.0
        else 
            lower_bound_root_node = r[3]["run_log"][1,:lower]
            upper_bound_root_node = r[3]["run_log"][1,:upper]
            relative_gap_root_node = r[3]["run_log"][1,:gap]
            lower_bound = r[3]["run_log"][end,:lower]
            upper_bound = r[3]["run_log"][end,:upper]
            relative_gap = r[3]["run_log"][end,:gap]
        end

        records = [
            (
                seed = seed,
                # Parameters
                k = k,
                m = n,
                n = n,
                p = p,
                num_indices = num_indices,
                noise = 0.0,
                γ = missing,
                λ = missing,
                node_selection = r[3]["run_details"]["node_selection"],
                bestfirst_depthfirst_cutoff = missing,
                optimality_gap = r[3]["run_details"]["optimality_gap"],
                root_only = root_only,
                altmin_flag = false,
                max_altmin_probability = missing,
                min_altmin_probability = missing,
                altmin_probability_decay_rate = missing,
                use_max_steps = false,
                max_steps = missing,
                time_limit = time_limit,
                use_disjunctive_cuts = true,
                disjunctive_cuts_type = "linear",
                disjunctive_cuts_breakpoints = "smallest_1_eigvec",
                disjunctive_sorting = false,
                presolve = presolve,
                add_basis_pursuit_valid_inequalities = add_basis_pursuit_valid_inequalities,
                add_Shor_valid_inequalities = add_Shor_valid_inequalities,
                add_Shor_valid_inequalities_fraction = (
                    isnothing(r[3]["run_details"]["add_Shor_valid_inequalities_fraction"]) ?
                    missing : r[3]["run_details"]["add_Shor_valid_inequalities_fraction"]
                ),
                add_Shor_valid_inequalities_iterative = false,
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
        continue
    end
end