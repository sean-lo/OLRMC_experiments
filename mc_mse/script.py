import fancyimpute
import numpy as np
import pandas as pd
from pathlib import Path
import os
from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer


# directory = Path(os.path.dirname(__file__))
directory = Path("mc_mse")
args = pd.read_csv(directory / "args.csv")

data = {
    "index": [],
    "k": [],
    "n": [],
    "p": [],
    "seed": [],
    "noise": [],
    "γ": [],
    "kind": [],
    "MSE_mf": [],
    "MSE_isvd": [],
}
for rank in [1, 2, 3, 4, 5]:
    rank_args = args[args["k"] == rank]
    for row in rank_args.iterrows():
        i = row[0] + 1
        print(i)
        try:
            A = np.genfromtxt(directory / f"data/{i}_A.csv", delimiter = ",")
            indices = np.array(
                np.genfromtxt(directory / f"data/{i}_indices.csv", delimiter = ","),
                bool,
            )
        except:
            continue

        A_incomplete = A.copy()
        A_incomplete[~indices] = np.nan
        A_zeroed = A.copy()
        A_zeroed[~indices] = 0.0

        # MatrixFactorization
        mf = fancyimpute.MatrixFactorization(rank = rank, verbose = False)
        A_mf = mf.solve(A_incomplete, ~indices)
        MSE_mf = np.mean(pow(A - A_mf, 2))

        # IterativeSVD
        isvd = fancyimpute.IterativeSVD(
            verbose = False, 
            gradual_rank_increase = False, 
            rank = rank,
        )
        A_isvd = isvd.solve(A_zeroed, ~indices)
        MSE_isvd = np.mean(pow(A - A_isvd, 2))

        data["index"].append(i)
        data["k"].append(row[1].k)
        data["n"].append(row[1].n)
        data["p"].append(row[1].p)
        data["seed"].append(row[1].seed)
        data["noise"].append(row[1].noise)
        data["γ"].append(row[1].γ)
        data["kind"].append(row[1].kind)
        data["MSE_mf"].append(MSE_mf)
        data["MSE_isvd"].append(MSE_isvd)

data_df = pd.DataFrame.from_dict(data)
data_df.head()
data_df.to_csv(directory / "data.csv", index = False)



# # IterativeSVD
i = 19300
rank = 5
A = np.genfromtxt(directory / f"data/{i}_A.csv", delimiter = ",")
indices = np.array(
    np.genfromtxt(directory / f"data/{i}_indices.csv", delimiter = ","),
    bool,
)
A_zeroed = A.copy()
A_zeroed[~indices] = 0.0



from sklearn.decomposition import TruncatedSVD

X_filled = A_zeroed.copy()
tsvd = TruncatedSVD(rank, algorithm = "arpack")

X_reduced = tsvd.fit_transform(X_filled)
X_reconstructed = tsvd.inverse_transform(X_reduced)
print(np.mean(pow(X_reconstructed - A_zeroed, 2)))
print(np.mean(pow(X_reconstructed - A, 2)))
print()
X_filled[~indices] = X_reconstructed[~indices]




isvd = fancyimpute.IterativeSVD(
    verbose = True, 
    gradual_rank_increase = False, 
    rank = 5,
)
A.shape

A_isvd = isvd.solve(A_zeroed, ~indices)
A_isvd - A
np.linalg.matrix_rank(A_isvd)
pow(A - A_isvd, 2)
np.sum(pow(A - A_isvd, 2))
np.mean(pow(A_zeroed - A_isvd, 2))
np.mean(pow(A - A_isvd, 2))


# A_isvd0 = isvd.solve(A_zeroed, ~indices)
# A_isvd0 - A
# np.linalg.matrix_rank(A_isvd0)
# MSE_isvd0 = np.mean(pow(A - A_isvd0, 2))
# print(MSE_isvd0)


# # IterativeImputer()

# ii = IterativeImputer(verbose = True)
# A_ii = ii.fit_transform(A_incomplete)
# A_ii - A
# np.linalg.matrix_rank(A_ii)
# MSE_ii = np.mean(pow(A - A_ii, 2))
# print(MSE_ii)

# # SoftImpute()

si = fancyimpute.SoftImpute(
    max_rank = 3,
    # shrinkage_value = 0.0,
    verbose = True,
    convergence_threshold = 1e-8,
)
A_incomplete = A.copy()
A_incomplete[~indices] = np.nan
A_si = si.fit_transform(A_zeroed, ~indices)
A_si - A
np.linalg.matrix_rank(A_si)
MSE_si = np.mean(pow(A - A_si, 2))
print(MSE_si)
si.X_filled - A
si.X_reconstruction - A



# # MatrixFactorization()

# mf = fancyimpute.MatrixFactorization(rank = 5, verbose = True)
# A_mf = mf.solve(A_incomplete, ~indices)

# mf.user_vecs
# mf.item_vecs

# print(A_mf - A)
# print(np.linalg.matrix_rank(A_mf))
# print(np.linalg.eigvals(np.matmul(A_mf.T, A_mf)))

# MSE_mf = np.mean(pow(A - A_mf, 2))
# print(MSE_mf)