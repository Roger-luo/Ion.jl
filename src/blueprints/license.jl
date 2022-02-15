@option struct License <: MustacheBlueprint
    template_dir::String = default_template("licenses")
    name::String = "MIT"
end

function src_file(bp::License, ctx::Context)
    return joinpath(bp.template_dir, bp.name)
end

function dst_file(::License, ctx::Context)
    return joinpath(ctx.kwargs.path, "LICENSE")
end

function blueprint_view(::License, ctx::Context)
    return Dict(
        "AUTHORS" => join(ctx.kwargs.authors, ", "),
        "YEAR" => year(today()),
    )
end
