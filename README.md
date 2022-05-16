# Ion

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Roger-luo.github.io/Ion.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Roger-luo.github.io/Ion.jl/dev)
[![Build Status](https://github.com/Roger-luo/Ion.jl/workflows/CI/badge.svg)](https://github.com/Roger-luo/Ion.jl/actions)
[![Coverage](https://codecov.io/gh/Roger-luo/Ion.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Roger-luo/Ion.jl)

A CLI&REPL toolkit for managing/developing Julia project & packages.

# Installation

<p>
Ion is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install Ion,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, and then type the following command:
</p>

For stable release:

```julia
pkg> add Ion
```

For current master:

```julia
pkg> add Ion#master
```

# How files are organized?

Each command has their own file or folder:

- implemented with only one file, then `<command>.jl`
- implemented with more than one file, then `<command>/<command>.jl` is the main file contains `include`

# Acknowledgement

The `ion create` command of this package is based on the implementation of `PkgTemplates`
but modified to support CLI usage (by supporting the option type interface of `Configurations`).

# License

MIT License
