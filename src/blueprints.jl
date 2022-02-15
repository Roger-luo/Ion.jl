default_template(paths::String...) = pkgdir(Blueprints, "templates", paths...)

@option struct TemplateFile
    root::String = default_template()
    path::String = "."
    file::String
end

"""
    Badge(hover::AbstractString, image::AbstractString, link::AbstractString)

Container for Markdown badge data.
Each argument can contain placeholders,
which will be filled in with values from [`combined_view`](@ref).

## Arguments
- `hover::AbstractString`: Text to appear when the mouse is hovered over the badge.
- `image::AbstractString`: URL to the image to display.
- `link::AbstractString`: URL to go to upon clicking the badge.
"""
@option struct Badge
    hover::String
    image::String
    link::String
end

Base.string(b::Badge) = "[![$(b.hover)]($(b.image))]($(b.link))"

include("blueprints/citation.jl")
include("blueprints/documenter.jl")
include("blueprints/license.jl")
include("blueprints/src_dir.jl")
include("blueprints/tests.jl")
include("blueprints/readme.jl")
