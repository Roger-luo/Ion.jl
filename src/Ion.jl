module Ion

using Comonicon

include("internal.jl")
include("repl.jl")

const CASTED_COMMANDS = Internal.CASTED_COMMANDS
@main

end
