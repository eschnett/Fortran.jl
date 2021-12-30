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
        while $(feval(d.cond))
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

const pos_integer = (f = Fun{Tuple{FInteger},FInteger}(+); Const(f))
const neg_integer = (f = Fun{Tuple{FInteger},FInteger}(-); Const(f))

const add_integer = (f = Fun{Tuple{FInteger,FInteger},FInteger}(+); Const(f))
const sub_integer = (f = Fun{Tuple{FInteger,FInteger},FInteger}(-); Const(f))
const mul_integer = (f = Fun{Tuple{FInteger,FInteger},FInteger}(*); Const(f))
const div_integer = (f = Fun{Tuple{FInteger,FInteger},FInteger}(÷); Const(f))
const mod_integer = (f = Fun{Tuple{FInteger,FInteger},FInteger}(%); Const(f))

const pos_real = (f = Fun{Tuple{FReal},FReal}(+); Const(f))
const neg_real = (f = Fun{Tuple{FReal},FReal}(-); Const(f))

const add_real = (f = Fun{Tuple{FReal,FReal},FReal}(+); Const(f))
const sub_real = (f = Fun{Tuple{FReal,FReal},FReal}(-); Const(f))
const mul_real = (f = Fun{Tuple{FReal,FReal},FReal}(*); Const(f))
const div_real = (f = Fun{Tuple{FReal,FReal},FReal}(/); Const(f))

end
