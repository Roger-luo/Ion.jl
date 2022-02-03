module Ion

using Comonicon

export patch, minor, major, current

include("internal.jl")
include("repl.jl")

const CASTED_COMMANDS = Internal.CASTED_COMMANDS
@main

end
