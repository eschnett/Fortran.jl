# Generate documentation with this command:
# (cd docs && julia --color=yes make.jl)

push!(LOAD_PATH, "..")

using Documenter
using Fortran

makedocs(; sitename="Fortran", format=Documenter.HTML(), modules=[Fortran])

deploydocs(; repo="github.com/eschnett/Fortran.jl.git", devbranch="main", push_preview=true)
