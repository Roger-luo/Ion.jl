@cast function create(path::String;
        template::String="project",
        name::String=basename(path),
        uuid::String="",
        authors::String="",
        username::String="",
        force::Bool=false
    )
    if !ispath(template)
        template_path = pkgdir(Internal, "templates", "configs", template * ".toml")
        isfile(template_path) || cmd_error("cannot find template $template")
    end
    t = from_toml(Blueprints.Template, template_path)

    # parse CLI inputs
    uuid = isempty(uuid) ? nothing : UUID(uuid)
    authors = isempty(authors) ? String[] : String.(split(authors, ','))
    username = isempty(username) ? nothing : username

    Blueprints.create(t, path; name, uuid, authors, username, force)
    return
end
