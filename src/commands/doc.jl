"""
subcommands for documentation.
"""
@cast module Doc

using Comonicon
using ..Internal: Package, julia, root_dir, develop_local_deps

"""
Build the documentation.

# Options

- `--dir=<name>`: name of the documentation dir, default is `docs`.
- `--root-path=<path/to/root/project>`: path to the root project,
    default will try to find the closest git repository.
"""
@cast function build(;dir="docs", root_path=root_dir())
    docs_dir = joinpath(root_path, "docs")
    makejl = joinpath(docs_dir, "make.jl")
    Package.init(docs_dir; root_path)
    run(`$(julia()) --project=$docs_dir $makejl`)
end

end