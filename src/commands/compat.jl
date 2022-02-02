function compat(version_spec::String="auto", path_to_project::String=pwd(); package::String="")
    toml = Base.current_project(path_to_project)
    toml === nothing && cmd_error("cannot find (Julia)Project.toml in $path_to_project")
    env = Pkg.Types.EnvCache(toml)
    compat = Dict{String, String}()
    for (name, uuid) in env.project.deps
        isempty(package) || package == name || continue
        env.manifest[uuid].version isa VersionNumber || continue # skip stdlib
        compat[name] = compat_version(env.manifest[uuid].version, version_spec)
    end
    compat["julia"] = compat_version(VERSION, version_spec)
    d = TOML.parsefile(toml)
    d["compat"] = merge(d["compat"], compat)
    write_project_toml(toml, d)
    return
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
