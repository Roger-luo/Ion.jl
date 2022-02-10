"""
    clone(package_or_url::String, to::String=pwd(); force::Bool=false)

Clone a package or remote URL to a local directory. 

# Intro

This command helps you clone a remote package repo from github.
The corresponding package or repo name will automatically remove
the `.jl` extension if it has one, e.g `https://github.com/JuliaLang/Example.jl`
will be downloaded as `Example`. And when cloning a repo that has
no write access, it will prompt to ask for a fork.

# Arguments

- `package_or_url`: package name or URL.
- `to`: local directory to download the git repo to.

# Flags

- `-f,--force`: force overwrite existing path.
"""
@cast function clone(package_or_url::String, to::String=pwd(); force::Bool=false)
    ispath(to) || mkpath(to)
    if isurl(package_or_url)
        clone_url(package_or_url, to, force)
    else
        clone_package(package_or_url, to, force)
    end
    return
end

function clone_url(url::String, to::String, force::Bool)
    if endswith(url, "jl.git")
        _clone(url, joinpath(to, basename(url)[1:end-7]), force)
    else
        _clone(url, joinpath(to, basename(url)), force)
    end
    return
end

function clone_package(package::String, to::String, force::Bool)
    info = find_package(package)
    isnothing(info) && cmd_error("cannot find $package in local registries")
    pkg_toml = get_registry_file(info.reg, joinpath(info.path, "Package.toml"))
    _clone(pkg_toml["repo"], joinpath(to, pkg_toml["name"]), force)
    return
end


function _clone(url::String, to::String, force::Bool)
    force && ispath(to) && rm(to; force=true, recursive=true)
    username = readchomp(`git config user.name`)
    auth = GitHub.authenticate(read_github_auth())
    rp = fetch_repo_from_url(url; auth=auth)

    local has_access
    try
        has_access = iscollaborator(rp, username; auth=auth)
    catch e
        has_access = false
    end

    if has_access
        git_clone(url, to)
    elseif prompt("do not have access to $url, fork?")
        @info "fork upstream repo: $(rp.full_name)"
        owned_repo = create_fork(rp; auth)
        git_clone(owned_repo.clone_url.uri, to)
        @info "setting upstream to $url"
        redirect_stdio(;stdout=devnull, stderr=devnull) do
            git_set_upstream(to; url)
        end
    end
    return
end
