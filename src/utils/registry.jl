function find_package(f, registry::String="")
    for reg in Pkg.Registry.reachable_registries()
        if isempty(registry) || registry == reg.name
            data = get_registry_file(reg, "Registry.toml")
            for (uuid, pkginfo) in data["packages"]
                f(uuid, pkginfo) && return (;uuid, reg, name=pkginfo["name"], path=pkginfo["path"])
            end
        end
    end
    return    
end

function find_package(package::String, registry::String="")
    find_package(registry) do uuid, pkginfo
        pkginfo["name"] == package
    end
end

function find_max_version(package::String, registry::String="")
    info = find_package(package, registry)
    info === nothing && return

    versions = get_registry_file(info.reg, joinpath(info.path, "Versions.toml"))
    max_version = findmax(VersionNumber.(keys(versions)))[1]
    return max_version
end

function get_registry_file(reg, path::String)
    return if isnothing(reg.in_memory_registry)
        TOML.parsefile(joinpath(reg.path, path))
    else
        TOML.parse(reg.in_memory_registry[path])
    end
end
