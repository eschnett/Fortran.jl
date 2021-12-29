using Fortran
using InteractiveUtils
using Test

fun = FFunction(:add, Int, [Var(:x, Int), Var(:y, Int)], Var[],
                Block([Loop(Var(:i, Int), Const(1, Int), Const(3, Int), Const(1, Int), Print(nothing, [Var(:i, Int)])),
                       Assign(Var(:add, Int), BinOp(:+, Var(:x, Int), Var(:y, Int), Int))]))

cfun = feval(fun)
println("Compiled function:")
println(cfun)
eval(cfun)

@code_warntype add(2, 3)
println("code_llvm:")
@code_llvm add(2, 3)
println("code_native:")
@code_native add(2, 3)
println("result:")
res = add(2, 3)
println(res)
@test res ≡ 5
