@blueprint struct Citation <: MustacheBlueprint
    template::String = TemplateFile(file="CITATION.bib")
    readme::Bool = false
end

blueprint_view(p::Citation, ctx::Context) = Dict(
    "AUTHORS" => join(ctx.kwargs.authors, ", "),
    "MONTH" => month(today()),
    "PKG" => ctx.kwargs.name,
    "URL" => "https://$(ctx.kwargs.host)/$(ctx.kwargs.user)/$(ctx.kwargs.name).jl",
    "YEAR" => year(today()),
)
