module Ion

using Comonicon

export patch, minor, major, current

include("internal.jl")
include("repl.jl")

const CASTED_COMMANDS = Internal.CASTED_COMMANDS

"""
CLI&REPL toolkit for managing/developing
Julia project & packages.
"""
@main

end
