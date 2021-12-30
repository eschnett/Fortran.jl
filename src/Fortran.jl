module Fortran

# const Label = String
# 
# const TypeSpec = Union{}
# 
# const Body = Union{}
# 
# const MainProgram = Union{}
# const SubroutineSubprogram = Union{}
# const BlockDataSubprogram = Union{}
# 
# struct Ident
#     ident::String
# end
# 
# struct FunctionRange
#     functionParList::Vector{Ident}
#     body::Body
# end
# 
# struct FunctionSubprogram
#     label::Union{Nothing, Label}
#     typeSpec::Union{Nothing, TypeSpec}
#     functionName::Ident
#     functionRange::FunctionRange
# end
# 
# struct ProgramUnit
#     data::Union{MainProgram,FunctionSubprogram,SubroutineSubprogram,BlockDataSubprogram}
# end
# 
# struct ExecutableProgram
#     data::Vector{ProgramUnit}
# end

################################################################################

clean_code(expr) = expr
function clean_code(expr::Expr)
    expr = Expr(expr.head, map(clean_code, filter(arg -> !(arg isa LineNumberNode), expr.args))...)
    # Remove line numbers.
    # Line numbers are usually wrong because they point to this file,
    # instead of the file where the code originates.
    if expr.head ≡ :block && length(expr.args) == 1
        expr = expr.args[1]
    end
    return expr
end
export clean_code

function feval end
export feval

################################################################################

struct FLogical
    value::Int32
    FLogical(b::Bool) = new(b)
end
export FLogical
Base.Bool(l::FLogical) = Bool(l.value)
Base.:%(l::FLogical, ::Type{Bool}) = l.value % Bool

const FInteger = Int32
export FInteger
const FReal = Float32
export FReal
const FDoublePrecision = Float64
export FDoublePrecision
const FComplex = Complex{FReal}
export FComplex
const FDoubleComplex = Complex{FDoublePrecision}
export FDoubleComplex

struct Fun{Domain<:Tuple,Codomain} <: Function
    fun::Function
end
export Fun
@inline (f::Fun{Domain,Codomain})(xs...) where {Domain,Codomain} = f.fun((xs::Domain)...)::Codomain

################################################################################

abstract type FExpr end
export FExpr

struct Const <: FExpr
    value::Any
    type::Type
    Const(value::T, ::Type{T}) where {T} = new(value, T)
end
export Const
Const(value) = Const(value, typeof(value))
feval(c::Const) = c.value

struct Var <: FExpr
    name::Symbol
    type::Type
end
export Var
feval(v::Var) = :($(v.name)::$(v.type))

struct Call <: FExpr
    fun::FExpr
    args::Vector{FExpr}
end
export Call
feval(c::Call) = :($(feval(c.fun))($((feval(arg) for arg in c.args)...)))

abstract type Stmt end
export Stmt

struct Assign <: Stmt
    lhs::Var
    rhs::FExpr
end
export Assign
feval(a::Assign) = quote
    $(a.lhs.name) = $(a.lhs.type)($(feval(a.rhs)))
end

struct Block <: Stmt
    stmts::Vector{Stmt}
end
export Block
feval(b::Block) = quote
    $((feval(stmt) for stmt in b.stmts)...)
end

struct Do <: Stmt
    var::Var
    lbnd::FExpr
    ubnd::FExpr
    step::FExpr
    body::Stmt
end
export Do
function feval(d::Do)
    name = d.var.name
    type = d.var.type
    lbnd = Symbol(name, ".lbnd")
    ubnd = Symbol(name, ".ubnd")
    step = Symbol(name, ".step")
    count = Symbol(name, ".count")
    idx = Symbol(name, ".idx")
    quote
        $lbnd = $(feval(d.lbnd))
        $ubnd = $(feval(d.ubnd))
        $step = $(feval(d.step))
        $step == 0 && error("Do loop step is zero")
        $count = FInteger(($ubnd - $lbnd) ÷ $step)
        $name = $type($lbnd)
        for $idx in FInteger(0):($count)
            $(feval(d.body))
            $name += $type($step)
        end
    end
end

struct DoWhile <: Stmt
    cond::FExpr
    body::Stmt
end
export DoWhile
function feval(d::DoWhile)
    quote
        while $(feval(d.cond))::FLogical % Bool
            $(feval(d.body))
        end
    end
end

struct If <: Stmt
    branches::Vector{Pair{FExpr,Stmt}}
    default::Stmt
end
export If
function feval(i::If)
    stmt = feval(i.default)
    for branch in Iterators.reverse(i.branches)
        stmt = quote
            if $(feval(branch[1]))::FLogical % Bool
                $(feval(branch[2]))
            else
                $stmt
            end
        end
    end
    return stmt
end

struct Print <: Stmt
    format::Any                 # TODO
    exprs::Vector{FExpr}
end
export Print
feval(p::Print) = quote
    println(" ", $((feval(expr) for expr in p.exprs)...))
end

struct FFunction
    name::Symbol
    type::Type
    args::Vector{Var}
    vars::Vector{Var}
    body::Stmt
end
export FFunction
feval(f::FFunction) = quote
    function $(f.name)($((:($(arg.name)::$(arg.type)) for arg in f.args)...))
        $(feval(f.body))
        return $(Symbol(f.name, ".result"))::$(f.type)
    end
end

################################################################################

feq(x::T, y::T) where {T} = FLogical(x == y)
fne(x::T, y::T) where {T} = FLogical(x ≠ y)
fle(x::T, y::T) where {T} = FLogical(x ≤ y)
flt(x::T, y::T) where {T} = FLogical(x < y)
fge(x::T, y::T) where {T} = FLogical(x ≥ y)
fgt(x::T, y::T) where {T} = FLogical(x > y)

const pos_integer = Const(Fun{Tuple{FInteger},FInteger}(+))
const neg_integer = Const(Fun{Tuple{FInteger},FInteger}(-))

const add_integer = Const(Fun{Tuple{FInteger,FInteger},FInteger}(+))
const sub_integer = Const(Fun{Tuple{FInteger,FInteger},FInteger}(-))
const mul_integer = Const(Fun{Tuple{FInteger,FInteger},FInteger}(*))
const div_integer = Const(Fun{Tuple{FInteger,FInteger},FInteger}(÷))
const mod_integer = Const(Fun{Tuple{FInteger,FInteger},FInteger}(%))

const eq_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(feq))
const ne_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(fne))
const le_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(fle))
const lt_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(flt))
const ge_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(fge))
const gt_integer = Const(Fun{Tuple{FInteger,FInteger},FLogical}(fgt))

const pos_real = Const(Fun{Tuple{FReal},FReal}(+))
const neg_real = Const(Fun{Tuple{FReal},FReal}(-))

const add_real = Const(Fun{Tuple{FReal,FReal},FReal}(+))
const sub_real = Const(Fun{Tuple{FReal,FReal},FReal}(-))
const mul_real = Const(Fun{Tuple{FReal,FReal},FReal}(*))
const div_real = Const(Fun{Tuple{FReal,FReal},FReal}(/))

const eq_real = Const(Fun{Tuple{FReal,FReal},FLogical}(feq))
const ne_real = Const(Fun{Tuple{FReal,FReal},FLogical}(fne))
const le_real = Const(Fun{Tuple{FReal,FReal},FLogical}(fle))
const lt_real = Const(Fun{Tuple{FReal,FReal},FLogical}(flt))
const ge_real = Const(Fun{Tuple{FReal,FReal},FLogical}(fge))
const gt_real = Const(Fun{Tuple{FReal,FReal},FLogical}(fgt))

end
