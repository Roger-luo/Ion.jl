"""
    Template

Julia type for a template object.

# Fields

- `name`: name of the template.
- `description`: description of the template.

# Optional Fields

- `project`: configs for Julia project.
- `readme`: configs for README.
- `src`: configs for `src` directory.
- `git`: configs for `git` repository.
- `documenter`: configs for `documenter`.
- `license`: configs for license.
- `tests`: configs for project tests.
- `citation`: configs for project citations.
"""
@blueprint struct Template
    name::String
    description::String
    # we always have Project.toml
    project::JuliaProject = JuliaProject()
    readme::Maybe{Readme}
    src::Maybe{SrcDir}
    git::Maybe{GitRepo}
    documenter::Maybe{Documenter}
    license::Maybe{License}
    tests::Maybe{ProjectTest}
    citation::Maybe{Citation}
end

Base.show(io::IO, ::MIME"text/plain", x::Template) = GarishPrint.pprint_struct(IOContext(io, :include_defaults=>true), x)

function blueprints(t::Template)
    names = filter(!isequal(:name), fieldnames(Template))
    return map(names) do name
        getfield(t, name)
    end
end

function compile(t::Template, ctx::Context)
    nf = nfields(Template)
    for idx in 1:nf
        fieldname(Template, idx) === [:name, :description] && continue
        blueprint = getfield(t, idx)
        isnothing(blueprint) || compile(blueprint, ctx)
    end
    return
end

function create(t::Template, path::String;
        name::String=basename(path),
        uuid::Maybe{UUID}=nothing,
        authors::Vector{String}=String[],
        username::Maybe{String}=nothing,
        force::Bool=false,
    )
    if ispath(path) && force
        rm(path;force=true, recursive=true)
    end

    ispath(path) && error("$path already exists!")
        
    ctx = Context(;kwargs=(;path, name, username, authors, force), root=t)
    compile(t, ctx)
    return
end
