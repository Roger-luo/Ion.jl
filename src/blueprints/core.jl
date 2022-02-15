default_template(paths::String...) = pkgdir(Blueprints, "templates", paths...)

"""
    is_blueprint(x)

Return `true` if `x` is a blueprint type or instance.
"""
is_blueprint(x) = false

macro blueprint(ex)
    return esc(blueprint_m(__module__, ex))
end

macro blueprint(alias::String, ex)
    return esc(blueprint_m(__module__, ex, alias))
end

function blueprint_m(mod::Module, ex, type_alias=nothing)
    ex = macroexpand(mod, ex)
    def = Configurations.JLKwStruct(ex, type_alias)
    return quote
        # we alawys export the blueprint here
        # but this prob should be removed when
        # we generalize this concept
        export $(def.name)
        $(Configurations.codegen_option_type(mod, def))
        $Blueprints.is_blueprint(::$(def.name)) = true
        $Blueprints.is_blueprint(::Type{$(def.name)}) = true
        nothing
    end
end

"""
    @option struct Context
Type for storing the compile context.
    
# Fields
- `args::Tuple`: the input arguments.
- `kwargs::NamedTuple`: the input keyword arguments.
- `stack::NTuple{N, Blueprint}`: [`Blueprint`](@ref) stack, topmost is the current blueprint under compile.
- `state::Dict{Symbol, Any}`: compile states that each blueprint can pass in.
"""
Base.@kwdef struct Context{Args <: Tuple, Kwargs <: NamedTuple, Blueprint}
    # global inputs that is
    # not from config meta
    args::Args = ()
    kwargs::Kwargs = NamedTuple()
    root::Blueprint # the root blueprint
    # state
    state::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

function assert_blueprint(x)
    is_blueprint(x) || error("expect a blueprint struct type defined via @blueprint")
end

"""
    blueprints(parent)

Return the component blueprints inside a given `blueprint`
"""
function blueprints(x)
    assert_blueprint(x)
    return ()
end

function has_blueprint(ctx::Context, ::Type{T}) where T
    assert_blueprint(T)
    for each in blueprints(ctx.root)
        each isa T && return true
    end
    return false
end

function get_blueprint(ctx::Context, ::Type{T}) where T
    assert_blueprint(T)
    for each in blueprints(ctx.root)
        each isa T && return each
    end
    return
end

abstract type MustacheBlueprint end
function blueprint_view(::MustacheBlueprint, ctx::Context)
    return Dict{String, Any}()
end

function src_file(bp::MustacheBlueprint, ::Context)
    return joinpath(bp.template.root, bp.template.path, bp.template.file)
end

function dst_file(bp::MustacheBlueprint, ctx::Context)
    return joinpath(ctx.kwargs.path, bp.template.path, bp.template.file)
end

function compile(bp::MustacheBlueprint, ctx::Context)
    file = src_file(bp, ctx)::String
    text = render_from_file(file, blueprint_view(bp, ctx))
    dst = dst_file(bp, ctx)::String
    mkpath(dirname(dst))
    write(dst, text)
    return
end

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
