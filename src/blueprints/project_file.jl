@blueprint struct JuliaProject
    version::VersionNumber = v"0.1.0"
    deps::Vector{String} = String[]
end

Configurations.to_dict(::Type{JuliaProject}, x::VersionNumber) = string(x)

function compile(bp::JuliaProject, ctx::Context)
    project_name = ctx.kwargs.name
    project_path = ctx.kwargs.path
    if ispath(project_path)
        ctx.kwargs.force == true &&
            rm(project_path; force=true, recursive=true)
    end
    mkpath(project_path)

    # Project.toml
    d = Dict{String, Any}()
    if has_blueprint(ctx, SrcDir) # only create this for a project with src dir
        d["name"] = project_name
        d["uuid"] = haskey(ctx.kwargs, :uuid) ? string(ctx.kwargs.uuid) : string(uuid1())
        d["version"] = string(bp.version)
    end

    isempty(ctx.kwargs.authors) || (d["authors"] = ctx.kwargs.authors)
    d["deps"] = Dict{String, String}()
    d["compat"] = Dict{String, String}(
        "julia" => string(VERSION.major, ".", VERSION.minor)
    )

    file_path = joinpath(project_path, "Project.toml")
    open(file_path, "w+") do f
        write_project_toml(file_path, d)
    end

    isempty(bp.deps) || with_project(project_path) do
        Pkg.add(bp.deps)
    end
    return
end

function write_project_toml(filepath::String, d::Dict{String, Any})
    open(filepath, "w+") do f # following whatever Pkg does
        TOML.print(f, d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
end