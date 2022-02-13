module Internal

using Pkg
using UUIDs
using GitHub
# using TestEnv
using Comonicon
using GarishPrint
using Distributed
using Configurations
# using Glob: FilenameMatch, ismatch
using Comonicon.Tools: prompt

@static if Sys.which("git") === nothing # no system git
    using Git: git
else
    git() = Sys.which("git")
end

include("utils/utils.jl")

# commands
include("commands/release.jl")
include("commands/clone.jl")
include("commands/compat.jl")
# include("commands/test.jl")

# fix redirect color issue
# @static if !hasmethod(get, Tuple{Base.PipeEndpoint, Symbol, Any})
#     Base.get(::Base.PipeEndpoint, key::Symbol, default) = key === :color ? Base.get_have_color() : default 
# end
# Base.get(::Base.PipeEndpoint, key::Symbol, default) = key === :color ? Base.get_have_color() : default 

end