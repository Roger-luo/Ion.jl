module Blueprints

using Pkg
using TOML
using Dates
using UUIDs
using LibGit2
using Mustache
using GarishPrint
using Configurations

export is_blueprint, @blueprint, create


# this should be the first
include("core.jl")

include("project_file.jl")
include("git.jl")
include("citation.jl")
include("documenter.jl")
include("license.jl")
include("src_dir.jl")
include("tests.jl")
include("readme.jl")

# this should be the last
include("template.jl")

# GarishPrint.pprint_struct(stdout, Template(;name="precompile"))

end
