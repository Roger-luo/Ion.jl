function find_package(f, registry::String="")
    for reg in Pkg.Registry.reachable_registries()
        if isempty(registry) || registry == reg.name
            data = TOML.parsefile(joinpath(reg.path, "Registry.toml"))
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

    versions = TOML.parsefile(joinpath(info.reg.path, info.path, "Versions.toml"))
    max_version = findmax(VersionNumber.(keys(versions)))[1]
    return max_version
end
