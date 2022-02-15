@option struct Readme <: MustacheBlueprint
    template::TemplateFile = TemplateFile(file="README.md")
    inline_badges::Bool = false
end

function blueprint_view(p::Readme, ctx::Context)
    return Dict(
        "HAS_CITATION" => has_blueprint(ctx, Citation) && get_blueprint(ctx, Citation).readme,
        "HAS_INLINE_BADGES" => !isempty(strings) && p.inline_badges,
        "PKG" => ctx.kwargs.name,
    )
end

badge_order() = [
    Documenter{GitHubActions},
    Documenter{GitLabCI},
    Documenter{TravisCI},
    GitHubActions,
    GitLabCI,
    TravisCI,
    AppVeyor,
    DroneCI,
    CirrusCI,
    Codecov,
    Coveralls,
]
