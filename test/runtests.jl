using Fortran
using InteractiveUtils
using Test

@testset "Simple test" begin
    fun = FFunction(:add, FInteger, [Var(:x, FInteger), Var(:y, FInteger)], Var[],
                    Block([Assign(Var(:var"add.result", FInteger),
                                  Call(Fortran.add_integer, FExpr[Var(:x, FInteger), Var(:y, FInteger)]))]))

    cfun = clean_code(feval(fun))
    println("Compiled function:")
    println(cfun)
    eval(cfun)

    arg1 = FInteger(2)
    arg2 = FInteger(3)
    println("code_warntype:")
    @code_warntype add(arg1, arg2)
    println("code_llvm:")
    @code_llvm add(arg1, arg2)
    println("code_native:")
    @code_native add(arg1, arg2)
    println("result:")
    res = add(arg1, arg2)
    println(res)
    @test res ≡ FInteger(5)
end

@testset "Do loop" begin
    fun = FFunction(:loop, FInteger, [Var(:imin, FInteger), Var(:imax, FInteger)], [Var(:count, FInteger), Var(:i, FInteger)],
                    Block([Assign(Var(:count, FInteger), Const(FInteger(0))),
                           Do(Var(:i, FInteger), Var(:imin, FInteger), Var(:imax, FInteger), Const(FInteger(1)),
                              Block([Assign(Var(:count, FInteger),
                                            Call(Fortran.add_integer, FExpr[Var(:count, FInteger), Const(FInteger(1))]))])),
                           Assign(Var(:var"loop.result", FInteger), Var(:count, Integer))]))
    cfun = clean_code(feval(fun))
    println("Compiled function:")
    println(cfun)
    eval(cfun)
    println("code_warntype:")
    @code_warntype loop(FInteger(2), FInteger(5))
    println("code_llvm:")
    @code_llvm loop(FInteger(2), FInteger(5))
    println("code_native:")
    @code_native loop(FInteger(2), FInteger(5))
    println("result:")
    res = loop(FInteger(2), FInteger(5))
    println(res)
    @test res ≡ FInteger(5 - 2 + 1)
end

@testset "Do-while loop" begin
    fun = FFunction(:loop2, FInteger, [Var(:imin, FInteger), Var(:imax, FInteger)], [Var(:count, FInteger), Var(:i, FInteger)],
                    Block([Assign(Var(:count, FInteger), Const(FInteger(0))), Assign(Var(:i, FInteger), Var(:imin, FInteger)),
                           DoWhile(Call(Fortran.le_integer, FExpr[Var(:i, FInteger), Var(:imax, FInteger)]),
                                   Block([Assign(Var(:count, FInteger),
                                                 Call(Fortran.add_integer, FExpr[Var(:count, FInteger), Const(FInteger(1))])),
                                          Assign(Var(:i, FInteger),
                                                 Call(Fortran.add_integer, FExpr[Var(:i, FInteger), Const(FInteger(1))]))])),
                           Assign(Var(:var"loop2.result", FInteger), Var(:count, Integer))]))
    cfun = clean_code(feval(fun))
    println("Compiled function:")
    println(cfun)
    eval(cfun)
    println("code_warntype:")
    @code_warntype loop2(FInteger(2), FInteger(5))
    println("code_llvm:")
    @code_llvm loop2(FInteger(2), FInteger(5))
    println("code_native:")
    @code_native loop2(FInteger(2), FInteger(5))
    println("result:")
    res = loop2(FInteger(2), FInteger(5))
    println(res)
    @test res ≡ FInteger(5 - 2 + 1)
end

@testset "If statment loop" begin
    fun = FFunction(:cond, FInteger, [Var(:c, FLogical), Var(:x, FInteger), Var(:y, FInteger)], Var[],
                    If([Var(:c, FLogical) => Assign(Var(:var"cond.result", FInteger), Var(:x, FInteger))],
                       Assign(Var(:var"cond.result", FInteger), Var(:y, FInteger))))
    cfun = clean_code(feval(fun))
    println("Compiled function:")
    println(cfun)
    eval(cfun)
    println("code_warntype:")
    @code_warntype cond(FLogical(true), FInteger(2), FInteger(5))
    println("code_llvm:")
    @code_llvm cond(FLogical(true), FInteger(2), FInteger(5))
    println("code_native:")
    @code_native cond(FLogical(true), FInteger(2), FInteger(5))
    println("result:")
    res = cond(FLogical(true), FInteger(2), FInteger(5))
    println(res)
    @test cond(FLogical(true), FInteger(2), FInteger(5)) ≡ FInteger(2)
    @test cond(FLogical(false), FInteger(2), FInteger(5)) ≡ FInteger(5)
end
