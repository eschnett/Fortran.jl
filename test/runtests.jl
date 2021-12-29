using Fortran
using InteractiveUtils
using Test

fun = FFunction(:add, FInteger, [Var(:x, FInteger), Var(:y, FInteger)], Var[],
                Block([Loop(Var(:i, FInteger), Const(1, FInteger), Const(3, FInteger), Const(1, FInteger),
                            Print(nothing, [Var(:i, FInteger)])),
                       Assign(Var(:add, FInteger), BinOp(:+, Var(:x, FInteger), Var(:y, FInteger), FInteger))]))

cfun = feval(fun)
println("Compiled function:")
println(cfun)
eval(cfun)

arg1 = FInteger(2)
arg2 = FInteger(3)
@code_warntype add(arg1, arg2)
println("code_llvm:")
@code_llvm add(arg1, arg2)
println("code_native:")
@code_native add(arg1, arg2)
println("result:")
res = add(arg1, arg2)
println(res)
@test res ≡ FInteger(5)
