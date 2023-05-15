# Experiments for Optimal Low-Rank Matrix Completion: Semidefinite Relaxations and Eigenvector Disjunctions

Repository of numerical experiments for the paper [Optimal Low-Rank Matrix Completion: Semidefinite Relaxations and Eigenvector Disjunctions](https://optimization-online.org/2023/05/optimal-low-rank-matrix-completion-semidefinite-relaxations-and-eigenvector-disjunctions/).

## Use

- Check that you have a valid installation of `Mosek`, as well as the package `OptimalMatrixCompletion.jl` (link [here](github.com/sean-lo/OptimalMatrixCompletion.jl)) installed.
- The `/postprocessing` folder contains all postprocessing scripts, that transform raw data into tables and plots that appear in the paper.
    - A list corresponding figure and table numbers in the paper to file names in `/postprocessing/tables` and `/postprocessing/plots` is included in `/postprocessing/README.md`.
- The experiments are grouped by folder, and are in all folders other than `/postprocessing`.
    - If you would like to run them, run the `script.jl` files attached in each subdirectory as follows:
        ```
        # cd to the subdirectory containing script.jl
        julia script.jl
        ```
    - These script files were made to run on a distributed computing cluster; if you are running them locally on your machine, change the following lines:
        ```
        task_index = parse(Int, ARGS[1]) + 1
        n_tasks = parse(Int, ARGS[2])   
        ```
        to:
        ```
        task_index = 1
        n_tasks = 1
        ```
        (You can also use other values if you want to run only a subset of the instances.)
    - After execution, the results of individual instances will appear in the corresponding `/records` subdirectory.