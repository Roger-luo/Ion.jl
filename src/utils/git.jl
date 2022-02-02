# some convenient helper function for Git CLI

function remote_repo_url(repo::String=pwd(); remote::String="origin")
    return cd(repo) do
        String(readchomp(`$(git()) config --get remote.$remote.url`))
    end
end

function remote_exists(repo::String=pwd())
    url = remote_repo_url(repo)
    p = cd(repo) do
        redirect_stdio(stderr=devnull, stdout=devnull) do
            run(ignorestatus(`$(git()) ls-remote --exit-code $url`))
        end
    end
    return p.exitcode == 0
end

function default_branch(repo::String=pwd(); remote::String="origin")
    remote_exists(repo) || error("cannot determine default branch, remote does not exist")

    url = remote_repo_url(repo)
    return cd(repo) do
        s = redirect_stdio(stderr=devnull) do
            readchomp(ignorestatus(`$(git()) ls-remote --symref $url HEAD`))
        end
        m = match(r"'s|^ref: refs/heads/(\S+)\s+HEAD|\1|p'", s)
        m === nothing && error("invalid remote response: $s")
        return String(m[1])
    end
end

function current_branch(repo::String=pwd())
    return cd(repo) do
        String(readchomp(`$(git()) rev-parse --abbrev-ref HEAD`))
    end
end

function checkout(repo::String=pwd(); branch::String, quiet::Bool=false)
    cd(repo) do
        if quiet
            run(`$(git()) checkout --quiet $branch`)
        else
            run(`$(git()) checkout $branch`)
        end
    end
end

function checkout(f, repo::String=pwd(); branch::String, quiet::Bool=false)
    current_br = current_branch(repo)
    checkout(repo; branch, quiet)
    ret = f()
    checkout(repo; branch=current_br, quiet)
    return ret
end

function git_clone(url::String, to::String)
    run(`$(git()) clone $url $to`)
end

function git_set_upstream(repo::String=pwd(); url::String)
    cd(repo) do
        run(`$(git()) remote add upstream $url`)
        run(`$(git()) fetch upstream`)
        main = default_branch(repo; remote="upstream")
        run(`$(git()) branch --set-upstream-to=upstream/$main`)
    end
end

function get_head_sha256(repo::String=pwd(); branch=current_branch(repo))
    return cd(repo) do
        String(readchomp(`$(git()) show -s --format="%H" $branch`))
    end
end

function list_branches(repo::String=pwd(); remote::Bool=false)
    return cd(repo) do
        results = readchomp(`$(git()) for-each-ref --format='%(refname:short)' refs/heads`)
        String.(split(results, '\n'))
    end
end

function git_get_toplevel_path(path::String=pwd())
    return cd(path) do
        String(readchomp(`git rev-parse --show-toplevel`))
    end
end

function isdiff(repo::String=pwd(); cached::Bool=false)
    return cd(repo) do
        if cached
            p = run(ignorestatus(`git diff --cached --quiet --exit-code`))
        else
            p = run(ignorestatus(`git diff --quiet --exit-code`))
        end
        return p.exitcode == 1
    end
end

isdirty(repo::String=pwd(); cached::Bool=false) = isdiff(repo; cached)

function github_repo(repo::String, remote="origin")
    url = remote_repo_url(repo; remote)
    github_https = "https://github.com/"
    github_ssh = "git@github.com:"
    if startswith(url, github_https)
        if endswith(url, ".git")
            return url[length(github_https)+1:end-4]
        else
            return url[length(github_https)+1:end]
        end
    elseif startswith(url, github_ssh)
        return url[length(github_ssh)+1:end-4]
    else
        return
    end
end

function fetch_repo_from_url(url; options...)
    HTTPS_GITHUB = "https://github.com/"
    GIT_GITHUB = "git@github.com:"
    if startswith(url, HTTPS_GITHUB) && endswith(url, ".git")
        repo = GitHub.repo(url[length(HTTPS_GITHUB)+1:end-4]; options...)
    elseif startswith(url, GIT_GITHUB) && endswith(url, ".git")
        repo = GitHub.repo(url[length(GIT_GITHUB)+1:end-4]; options...)
    else
        return "not a GitHub repo, please visit $(url) for details about this package"
    end

    return repo
end