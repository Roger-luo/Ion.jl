@blueprint "github" struct GitHubRepo
    type::Reflect
    user::String # user may not be the same as user.name
    repo::Maybe{String} # if nothing use pkg name
end

@blueprint "gitlab" struct GitLabRepo
    type::Reflect
    user::String
    repo::Maybe{String} # if nothing use pkg name
end

@blueprint struct GitIgnoreFile
    patterns::Vector{String} = String[]
end

@blueprint struct GitRepo
    name::Maybe{String}
    email::Maybe{String}
    branch::Maybe{String}
    ssh::Bool = false
    suffix::String = ".jl"
    gpgsign::Bool = false
    ignore::GitIgnoreFile = GitIgnoreFile()
    repo::Maybe{Union{GitHubRepo, GitLabRepo}}
end

function compile(p::GitRepo, ctx::Context)
    project_name = ctx.kwargs.name
    project_path = ctx.kwargs.path

    LibGit2.with(LibGit2.init(project_path)) do repo
        LibGit2.with(GitConfig(repo)) do config
            foreach((:name, :email)) do k
                v = getproperty(p, k)
                v === nothing || LibGit2.set!(config, "user.$k", v)
            end
        end
        LibGit2.commit(repo, "Initial commit")

        # setup default branch
        default = LibGit2.branch(repo)
        branch = something(p.branch, default)
        if branch != default
            LibGit2.branch!(repo, branch)
            LibGit2.delete_branch(LibGit2.GitReference(repo, "refs/heads/$default"))
        end
    end
    # move to remote repo setup
    isnothing(p.repo) || compile(p.repo, ctx)
    compile(p.ignore, ctx)
    return
end

function compile(p::GitHubRepo, ctx::Context)
    project_path = ctx.kwargs.path
    url = if isnothing(p.repo)
        get_default_repo_url(p.repo, project_name, p.suffix, p.ssh)
    else
        p.repo
    end

    LibGit2.with(LibGit2.GitRepo(project_path)) do repo
        close(LibGit2.GitRemote(repo, "origin", url))
    end
    # TODO: create GitHub/GitLab repo
    return
end

function get_default_repo_url(repo::GitHubRepo, pkg::String, suffix::String, ssh::Bool)
    return if ssh
        "git@github.com:$(repo.user)/$pkg$suffix.git"
    else
        "https://github.com/$(repo.user)/$pkg$suffix"
    end
end

function compile(p::GitIgnoreFile, ctx::Context)
    ignore_list = get(ctx.state, :gitignore, String[])
    append!(ignore_list, p.patterns)
    write(joinpath(ctx.kwargs.path, ".gitignore"), join(ignore_list, "\n"))
    return
end

# function compile(p::GitCommitFiles, ctx::Context)
#     project_path = ctx.kwargs.path

#     # Special case for PkgTemplates/#211
#     if Sys.iswindows()
#         files = filter(f->startswith(f, "_git2_"), readdir(project_path))
#         foreach(f -> rm(joinpath(project_path, f)), files)
#     end

#     LibGit2.with(LibGit2.GitRepo(project_path)) do repo
#         LibGit2.add!(repo, ".")
#         LibGit2.commit(repo, p.msg)
#     end
#     return
# end