# Fortran.jl

Execute Fortran code from Julia.

* [![Documenter](https://img.shields.io/badge/docs-dev-blue.svg)](https://eschnett.github.io/Fortran.jl/dev)
* [![GitHub
  CI](https://github.com/eschnett/Fortran.jl/workflows/CI/badge.svg)](https://github.com/eschnett/Fortran.jl/actions)
* [![Codecov](https://codecov.io/gh/eschnett/Fortran.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eschnett/Fortran.jl)

(This project is at the moment just a proof of principle.)

The ultimate goal is to have a parser that reads Fortran code and
generates Julia code (i.e. Julia expressions) from them. This would
allow a seamless integration of Fortran and Julia code, and might even
make it easier to convert Fortran code to Julia.

To achieve this goal, three major pieces need to exist:
- A Fortran parser that generates a Fortran abstract syntax tree
- Defining a Fortran machine, and a pass that converts the abstract
  syntax tree to the Fortran machine tree
- A Fortran "compiler" that converts the abstract machine to Julia.

Writing a parser for Fortran is a well-understood problem. The
[Fortran standard](https://wg5-fortran.org) defines the language well,
and this part of the probme is thus "straightforward but tedious".

This project here takes the first steps towards defining a Fortran
machine. So far, very little is supported -- you can define functions
that use scalar variables and perform simple arithmetic, as well as
loops and if statements.

Finally, converting the Fortran machine tree to Julia is also
straightforward since Julia is a lispy language, and thus generating
Julia code in Julia is well supported.

## Related Projects:

- [Translate fortran to julia](https://discourse.julialang.org/t/translate-fortran-to-julia/23624)
- [Browsable Fortran 77 and 90 Grammar](http://slebok.github.io/zoo/fortran/f90/waite-cordy/extracted/index.html)
- [Fortran-Julia conversion script](https://gist.github.com/rafaqz/fede683a3e853f36c9b367471fde2f56)
