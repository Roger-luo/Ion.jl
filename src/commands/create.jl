"""
Create a Julia package/project from
given template.

# Args

- `path`: path of the project to create

# Options

- `--template=<template name>`: template to use, default is the `project` template.
- `--name=<string>`: name of the package, default is the `basename` of `path`.
- `--uuid=<string>`: UUID of the package, default is generated using `uuid1`.
- `--authors=<string>`: authors list, default is empty.
- `--username=<string>`: username of `git`, default will use the system git config.

# Flags

- `-f,--force`: if `path` exists overwrite the content in `path`.
"""
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
