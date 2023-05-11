using CategoricalArrays
using Printf

floatstring(x::Float64) = @sprintf("%.2e", x)
function Base.unique(ctg::CategoricalArray)
    l = levels(ctg)
    newctg = CategoricalArray(l)
    levels!(newctg, l)
end

function num_indices_to_string(p, k, n, num_indices)
    if num_indices == Int(ceil(p * k * n))
        indices_string = "pkn"
    elseif num_indices == Int(ceil(p * k * n * log10(n)))
        indices_string = "pkn log_{10}(n)"
    elseif num_indices == Int(ceil(p * k * n^(1.2) * log10(n) / 10^(0.2)))
        indices_string = "pkn^{6/5} log_{10}(n) / 10^{1/5}"
    elseif num_indices == Int(ceil(p * k * n^(1.5) / sqrt(10.0)))
        indices_string = "pkn^{3/2} / 10^{1/2}"
    elseif num_indices == Int(ceil(p * k * n^2 / 10.0))
        indices_string = "pkn^{2} / 10"
    end
    return indices_string
end

function string_to_num_indices(p, k, n, kind)
    if kind == "pkn"
        num_indices = Int(ceil(p * k * n))
    elseif kind == "pkn log_{10}(n)"
        num_indices = Int(ceil(p * k * n * log10(n)))
    elseif kind == "pkn^{6/5} log_{10}(n) / 10^{1/5}"
        num_indices = Int(ceil(p * k * n^(1.2) * log10(n) / 10^(0.2)))
    elseif kind == "pkn^{3/2} / 10^{1/2}"
        num_indices = Int(ceil(p * k * n^(1.5) / sqrt(10.0)))
    elseif kind == "pkn^{2} / 10"
        num_indices = Int(ceil(p * k * n^2 / 10.0))
    end
    return num_indices
end

function array_to_string(array_string)
    if array_string == "Int64[]" 
        return "none"
    elseif array_string == "[4]" 
        return "4"
    elseif array_string == "[4, 3]" 
        return "43"
    elseif array_string == "[4, 3, 2]" 
        return "432"
    elseif array_string == "[4, 3, 2, 1]" 
        return "4321"
    end
end