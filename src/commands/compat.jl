"""
create compat in `Project.toml`. Update the compat to latest non-breaking
version by semantic version definition (latest minor version for `0.x.y`,
latest major version for other case).

# Arguments

- `version_spec`: version_spec to be compatible with, can be `patch`, `minor`, `major` or `auto`.
- `path_to_project`: path to the project, default is the current working directory.

# Options

- `-p,--package=<name>`: package selector, use this option to update specified package compat only.

# Flags

- `--overwrite`: force update all compat by overwrite old compat.
"""
@cast function compat(version_spec::String="auto", path_to_project::String=pwd(); package::String="", overwrite::Bool=false)
    toml = Base.current_project(path_to_project)
    toml === nothing && cmd_error("cannot find (Julia)Project.toml in $path_to_project")
    d = TOML.parsefile(toml)
    compat = get!(Dict{String, String}, d, "compat")
    env = Pkg.Types.EnvCache(toml)
    for (name, uuid) in env.project.deps
        isempty(package) || package == name || continue
        env.manifest[uuid].version isa VersionNumber || continue # skip stdlib
        update_compat!(compat, name, env.manifest[uuid].version, version_spec, overwrite)
    end
    update_compat!(compat, "julia", VERSION, version_spec, overwrite)
    write_project_toml(toml, d)
    return
end

function update_compat!(compat::Dict{String, String}, name::String, version::String, version_spec::String, overwrite::Bool)
    compat_spec = compat_version(version, version_spec)
    compat[name] = if overwrite
        compat_spec
    else
        append_compat_spec(compat, name, compat_spec)
    end
    return compat
end

function append_compat_spec(compat::Dict{String, String}, name::String, spec::String)
    haskey(compat, name) || return spec
    # TODO: use more compact format, e.g x.y.z-a.b.c
    return string(compat[name], ", ", spec)
end

function compat_version(version::VersionNumber, version_spec::String)
    return if version_spec == "patch"
        string(version.major, ".", version.minor, ".", version.patch)
    elseif version_spec == "minor"
        string(version.major, ".", version.minor)
    elseif version_spec == "major"
        string(version.major)
    elseif version_spec == "auto"
        if version.major == 0
            string(version.major, ".", version.minor)
        else
            string(version.major)
        end
    else
        cmd_error("invalid version spec: $version_spec")
    end
end
