@blueprint struct SrcDir <: MustacheBlueprint
    template::TemplateFile = TemplateFile(path="src", file="module.jl")
end

blueprint_view(::SrcDir, ctx::Context) = Dict(
    "PKG" => ctx.kwargs.name,
)

function dst_file(::SrcDir, ctx::Context)
    joinpath(ctx.kwargs.path, "src", ctx.kwargs.name * ".jl")
end
