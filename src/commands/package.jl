"""
subcommands for managing large Julia package
that contains sub-packages in its `lib` directory.
"""
@cast module Package

using Pkg
using TOML
using Comonicon

function find_dot_git(current::String=pwd())
    ispath(current) || return
    ".git" in readdir(current) && return abspath(current)
    return find_dot_git(joinpath(current, ".."))
end

function find_root_project()
    dot_git_dir = find_dot_git()
    isnothing(dot_git_dir) && throw(
        ArgumentError("cannot find root project git repository")
    )
    isfile(joinpath(dot_git_dir, "Project.toml")) ||
    isfile(joinpath(dot_git_dir, "JuliaProject.toml")) ||
    throw(ArgumentError("expect (Julia)Project.toml exists"))
    return dot_git_dir
end

root_dir(xs::String...) = joinpath(find_root_project(), xs...)

function collect_libs(root::String; include_main::Bool=false)
    lib_path = joinpath(root, "lib")
    pkgs = Pkg.PackageSpec[]
    foreach_subpackage(root) do package, path
        push!(pkgs, Pkg.PackageSpec(path=package_path))
    end
    include_main && push!(pkgs, Pkg.PackageSpec(path = root))
    return pkgs
end

function collect_lib_deps(root::String, subpackage_path::String)
    lib_dir = joinpath(root, "lib")
    isdir(lib_dir) || return Pkg.PackageSpec[]

    lib_pkgs = String[]
    foreach_subpackage(root) do package, path
        push!(lib_pkgs, package)
    end

    main_pkg_name = TOML.parsefile(joinpath(root, "Project.toml"))["name"]
    d = TOML.parsefile(joinpath(subpackage_path, "Project.toml"))
    deps = get(d, "deps", Dict())
    names = [name for name in keys(deps) if name in lib_pkgs || name == main_pkg_name]

    paths = map(names) do name
        name == main_pkg_name && return root
        return joinpath(root, "lib", name)
    end

    pkgs = map(paths) do path
        Pkg.PackageSpec(;path)
    end
    return pkgs
end

function foreach_subpackage(f, root_path::String)
    lib_dir = joinpath(root_path, "lib")
    isdir(lib_dir) || return
    for subpackage in readdir(lib_dir)
        subpackage_path = joinpath(root_path, "lib", subpackage)
        isdir(subpackage_path) || continue
        f(subpackage, subpackage_path)
    end
    return
end

function develop_local_deps(root_path::String, project_path::String)
    Pkg.activate(project_path; io=devnull)
    pkgs = collect_lib_deps(root_path, project_path)
    isempty(pkgs) || Pkg.develop(pkgs; io=devnull)
    return
end

"""
    initall(;root_path::String=root_dir(), no_docs::Bool=false, no_examples::Bool=false)

Init all pacakge dependencies by developing
local dependencies in `lib`.

# Intro

This command will init the local dependencies
of folders such as `lib`, `examples` and `docs`.

# Options

- `--root-path=<path/to/package>`: path to the root of the package,
    default will try to find the closest git repository.

# Flags

- `--no-docs`: exclude `docs` folder.
- `--no-examples`: exclude `examples` folder.
"""
@cast function initall(;root_path::String=root_dir(), no_docs::Bool=false, no_examples::Bool=false)
    proj_path = Pkg.project().path

    foreach_subpackage(root_path) do package, path
        develop_local_deps(root_path, path)
    end

    # setup docs env
    docs_dir = joinpath(root_path, "docs")
    isdir(docs_dir) && develop_local_deps(root_path, docs_dir)

    # setup examples env
    examples_dir = joinpath(root_path, "examples")
    isdir(examples_dir) && develop_local_deps(root_path, examples_dir)

    # dev libs for root package
    develop_local_deps(root_path, root_path)

    # activate current project
    Pkg.activate(proj_path; io=devnull)
    return
end

"""
    init(path::String; root_path::String=root_dir())

Init a project environment at `path` by developing local dependencies from `root_path`.

# Args

- `path`: path to the project to init.

# Options

- `--root-path=<path/to/package>`: path to the root of the package,
    default will try to find the closest git repository.

"""
@cast function init(path::String; root_path::String=root_dir())
    proj_path = Pkg.project().path
    ispath(path) || cmd_error("$path does not exists")
    develop_local_deps(root_path, path)
    # activate current project
    Pkg.activate(proj_path; io=devnull)
    return
end

end
