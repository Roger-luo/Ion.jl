# GITHUB_TOKEN is used in github actions
# GITHUB_AUTH is suggested by GitHub.jl
const ENV_GITHUB_TOKEN_NAMES = ["GITHUB_TOKEN", "GITHUB_AUTH"]

function read_github_auth()
    for key in ENV_GITHUB_TOKEN_NAMES
        if haskey(ENV, key)
            return ENV[key]
        end
    end

    buf = Base.getpass("GitHub Access Token (https://github.com/settings/tokens)")
    auth = read(buf, String)
    Base.shred!(buf)
    return auth
end
