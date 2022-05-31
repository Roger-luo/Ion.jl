"""
subcommands for managing large Julia package
that contains sub-packages in its `lib` directory.
"""
@cast module Package

using Pkg
using TOML
using Comonicon
using ..Internal: collect_lib_deps, foreach_subpackage, develop_local_deps

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
