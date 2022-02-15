const TEST_UUID = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
const TEST_DEP = PackageSpec(; name="Test", uuid=TEST_UUID)

@option struct ProjectTest <: MustacheBlueprint
    template::TemplateFile = TemplateFile(path="test", file="runtests.jl")
    project::Bool = false
end

blueprint_view(bp::ProjectTest, ctx::Context) = Dict(
    "PKG" => ctx.kwargs.name,
)

function compile(bp::ProjectTest, ctx::Context)
    invoke(compile, Tuple{MustacheBlueprint, Context}, bp, ctx)

    f = bp.project ? make_test_project : add_test_dependency
    f(ctx.kwargs.path)
end

function make_test_project(pkg_dir::AbstractString)
    with_project(joinpath(pkg_dir, "test")) do
        Pkg.add(TEST_DEP)
    end
end

function add_test_dependency(pkg_dir::AbstractString)
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    get!(Dict, toml, "extras")["Test"] = TEST_UUID
    get!(Dict, toml, "targets")["Test"] = ["Test"]
    write_project_toml(path, toml)

    touch(joinpath(pkg_dir, "Manifest.toml"))
    with_project(Pkg.update, pkg_dir)
end

function with_project(f, path::AbstractString)
    proj = Base.active_project()
    try
        Pkg.activate(path)
        return f()
    finally
        isnothing(proj) ? Pkg.activate() : Pkg.activate(proj)
    end
end
