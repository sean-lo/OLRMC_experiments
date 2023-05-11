using CSV
using DataFrames

combine_df = vcat(
    [
        CSV.read("mc1_size/linear3/03/summary.csv", DataFrame),
        CSV.read("mc1_size/linear3/04/summary.csv", DataFrame),
    ]...
)
filter!(
    r -> (
        r.num_indices == Int(ceil(r.n * r.p * 1 * log10(r.n)))
    ),
    combine_df
)
CSV.write("mc1_size/linear3/summary.csv", combine_df)