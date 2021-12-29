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

function feval end
export feval

struct FLogical
    value::Int32
    FLogical(b::Bool) = new(b)
end
export FLogical
convert(::Type{Bool}, l::FLogical) = Bool(l.value)

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

abstract type FExpr end
export FExprt

struct Const <: FExpr
    value::Any
    type::Type
end
export Const
feval(c::Const) = :($(c.type)($(c.value)))

struct Var <: FExpr
    name::Symbol
    type::Type
end
export Var
feval(v::Var) = :($(v.name)::$(v.type))

struct Add <: FExpr
    expr1::FExpr
    expr2::FExpr
    type::Type
end
export Add
feval(a::Add) = :($(a.type)($(feval(a.expr1)) + $(feval(a.expr2))))

struct Sub <: FExpr
    expr1::FExpr
    expr2::FExpr
    type::Type
end
export Sub
feval(s::Sub) = :($(s.type)($(feval(s.expr1)) - $(feval(s.expr2))))

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

struct Loop <: Stmt
    var::Var
    lbnd::FExpr
    ubnd::FExpr
    step::FExpr
    body::Stmt
end
export Loop
function feval(l::Loop)
    name = l.var.name
    type = l.var.type
    lbnd = Symbol(name, ".lbnd")
    ubnd = Symbol(name, ".ubnd")
    step = Symbol(name, ".step")
    count = Symbol(name, ".count")
    idx = Symbol(name, ".idx")
    quote
        $lbnd = $(feval(l.lbnd))
        $ubnd = $(feval(l.ubnd))
        $step = $(feval(l.step))
        $step == 0 && error("Loop step is zero")
        $count = FInteger(($ubnd - $lbnd) ÷ $step)
        $name = $type($lbnd)
        for $idx in FInteger(0):($count)
            $(feval(l.body))
            $name += $type($step)
        end
    end
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
function feval(f::FFunction)
    quote
        function $(f.name)($((:($(arg.name)::$(arg.type)) for arg in f.args)...))
            $(f.name) = nothing
            $(feval(f.body))
            return $(f.name)::$(f.type)
        end
    end
end

end
