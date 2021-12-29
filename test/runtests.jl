using Fortran
using InteractiveUtils
using Test

fun = FFunction(:add, Int, [Var(:x, Int), Var(:y, Int)], Var[],
                [Assign(Var(:add, Int), BinOp(:+, Var(:x, Int), Var(:y, Int), Int))])

efun = feval(fun)
println(efun)
eval(efun)

@code_warntype add(2, 3)
@code_llvm add(2, 3)
@code_native add(2, 3)
@test add(2, 3) ≡ 5
