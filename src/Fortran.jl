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

abstract type FExpr end
export FExprt

struct Const <: FExpr
    value::Any
    type::Type
end
export Const
feval(c::Const) = :($(c.value)::$(c.type))

struct Var <: FExpr
    name::Symbol
    type::Type
end
export Var
feval(v::Var) = :($(v.name)::$(v.type))

struct BinOp <: FExpr
    op::Symbol
    op1::FExpr
    op2::FExpr
    type::Type
end
export BinOp
feval(b::BinOp) = :($(b.op)($(feval(b.op1)), $(feval(b.op2)))::$(b.type))

abstract type Stmt end
export Stmt

struct Assign <: Stmt
    lhs::Var
    rhs::FExpr
end
export Assign
feval(a::Assign) = quote
    $(a.lhs.name) = $(feval(a.rhs))::$(a.lhs.type)
end

struct FFunction
    name::Symbol
    type::Type
    args::Vector{Var}
    vars::Vector{Var}
    stmts::Vector{Stmt}
end
export FFunction
function feval(f::FFunction)
    quote
        function $(f.name)($((:($(arg.name)::$(arg.type)) for arg in f.args)...))
            $(f.name) = nothing
            $((feval(stmt) for stmt in f.stmts)...)
            return $(f.name)::$(f.type)
        end
    end
end

end
