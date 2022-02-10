@enum VersionSpec begin
    patch
    minor
    major
    current
end

"""
    release(version_spec[, path=pwd()]; kw...)

Release a new version for a package, e.g

```julia-repl
julia> pwd()
"/home/roger/julia/Comonicon"

julia> Ion.release(patch) # will release a new patch version on github
```

# Arguments

- `version_spec`: required, semantic version bump (`patch`, `minor`, `major`, `current`)
    or a specific version number to release (`VersionNumber` or valid version string).
- `path`: optional, path to the pacakge to release, default is `pwd()`.

# Keyword Arguments

- `registry`: optional, name of the registry to register, if not specified, will lookup
    if the package has been registered in local registries.
- `branch`: optional, branch to register, default is current branch.
- `note`: optional, release note.
"""
function release(
        version_spec::Union{VersionSpec, VersionNumber, String},
        path::String=pwd();
        registry::String="",
        branch::String=Internal.current_branch(path),
        note::String="", debug::Bool=false,
    )

    spec = if version_spec == patch
        "patch"
    elseif version_spec == minor
        "minor"
    elseif version_spec == major
        "major"
    else
        "current"
    end

    try
        Internal.release(spec, path; registry, branch, note, debug)
    catch e
        if e isa Comonicon.CommandExit
            return e.exitcode
        else
            rethrow(e)
        end
    end
end

for api in [:clone, :compat]
    md = @eval @doc(Internal.$api)
    @eval @doc $md function $api(args...; kw...)
        try
            Internal.$api(args...; kw...)
        catch e
            if e isa Comonicon.CommandExit
                return e.exitcode
            else
                rethrow(e)
            end
        end
    end
end
