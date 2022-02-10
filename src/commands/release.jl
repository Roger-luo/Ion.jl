using TOML
using UUIDs
using GitHub

Base.@kwdef struct VersionTokens
    major::String = "major"
    minor::String = "minor"
    patch::String = "patch"
end

const VERSION_TOKENS = VersionTokens()
Base.show(io::IO, vt::VersionTokens) = print(io, "(", vt.major, ", ", vt.minor, ", ", vt.patch, ")")
Base.in(version::String, tokens::VersionTokens) = (version == tokens.major) ||
    (version == tokens.minor) || (version == tokens.patch)

function is_version_number(version)
    occursin(r"[0-9]+.[0-9]+.[0-9]+", version) ||
        occursin(r"v[0-9]+.[0-9]+.[0-9]+", version)
end

struct ProjectToRelease
    name::String # package name
    path::String # path to the git repo
    subdir::String # subdir to the package
    toml::String # Project.toml
    uuid::UUID # project UUID
    version::Maybe{VersionNumber} # current version
    branch::String # branch to release

    # user inputs
    note::String
    version_spec::String
    release_version::VersionNumber
end

function ProjectToRelease(version_spec::String, path_to_project::String=pwd();
        branch::String=default_branch(path_to_project), note::String="")

    toml = Base.current_project(path_to_project)
    toml === nothing && cmd_error("cannot find (Julia)Project.toml in $path_to_project")
    path_to_project = dirname(toml)
    path_to_repo = git_get_toplevel_path(path_to_project)
    pkg = Pkg.Types.read_project(toml)
    subdir = relpath(path_to_project, path_to_repo)

    return ProjectToRelease(
        pkg.name, path_to_repo, subdir, abspath(toml),
        pkg.uuid, pkg.version, branch,
        note, version_spec,
        release_version(pkg.name, pkg.version, version_spec)
    )
end

Base.show(io::IO, ::MIME"text/plain", x::ProjectToRelease) = GarishPrint.pprint_struct(io, x)

# NOTE: About Registration Process
#
# 1. checkout to the release branch
# 2. 

"""
release a package.

# Intro

This command can release packages and auto bump versions for you
semantically. One will not need to remember how to type `JuliaRegistrator`
correctly but just use `ion release patch` under the package folder. Or
via the REPL interface as `Ion.release("patch")`

# Arguments

- `version_spec`: version number you want to release. Can be a specific version, "current"
    or either of $(VERSION_TOKENS)
- `path`: path to the project you want to release.

# Options

- `-r,--registry <registry name>`: registry you want to register the package.
    If the package has not been registered, ion will try to register
    the package in the General registry. Or the user needs to specify
    the registry to register using this option.
- `-b, --branch <branch name>`: branch you want to register.
- `--note <release note>`: optional, release note you would like to specify.
"""
@cast function release(version_spec::String, path::String=pwd();
        registry::String="",
        branch::String=current_branch(path),
        note::String="", debug::Bool=false,
    )
    project = ProjectToRelease(version_spec, path; branch, note)
    checkout(project.path; project.branch, quiet=true) do
        check_if_repo_dirty(project)
        check_release_info(project)
        sync_with_remote(project)
        try_register(registry, project)
    end
    return
end

function check_if_repo_dirty(project::ProjectToRelease)
    isdirty(project.path) &&
        cmd_error("package repository is dirty, please commit or stash changes.")
    return
end

function check_release_info(project::ProjectToRelease)
    if should_update_version(project)
        update_version!(project)
        commit_version_update(project)
    elseif prompt() do
            print("do you want to release current version ")
            printstyled(project.version; color=:light_cyan)
            print(" ?")
        end
    else
        cmd_exit()
    end
    return
end

function sync_with_remote(project::ProjectToRelease)
    @info "push local changes to remote"
    cd(project.path) do
        redirect_stdio(;stdout=devnull, stderr=devnull) do
            run(`$(git()) push origin $(project.branch)`)
        end
    end
    return
end

function try_register(registry::String, project::ProjectToRelease)
    try
        register(registry, project)
    catch e
        if should_update_version(project)
            run(`$(git()) revert --no-edit --no-commit HEAD`)
            run(`$(git()) commit -m "revert version bump due to an error occured in IonCLI"`)
            sync_with_remote(project)
            printstyled(" ✔  "; color=:light_green)
            println("revert version bump commit:")
        end
    end
    return
end

# ion release patch lib/EaRydCore
# ion release patch
function release_version(name::String, version::VersionNumber, version_spec::String)
    version_spec == "current" && return version
    Pkg.Registry.update() # make sure we always get latest version
    latest_version = find_max_version(name)

    if is_version_number(version_spec)
        version_number = VersionNumber(version_spec)
    elseif version_spec in VERSION_TOKENS
        version_number = bump_version(latest_version, version_spec)
    else
        cmd_error("invalid version spec: $(version_spec)")
    end

    if latest_version === nothing
        println("package not found in local registries")
    end

    print(" "^7, "version to release: ")
    printstyled(version_number; color=:light_cyan)
    println()

    if version == latest_version
        # current is same as latest version
        print(" "^7, "current/latest version: ")
        printstyled(latest_version; color=:light_cyan)
        println()
    elseif version > latest_version
        # current is newer than latest version
        # this may because we had a failed manual
        # version bump before
        println("your current version is already larger than latest release")

        print(" "^10, "current version: ")
        printstyled(version; color=:light_cyan)
        println()

        print(" "^10, "latest version: ")
        printstyled(latest_version; color=:light_cyan)
        println()

        if is_version_continuously_greater(latest_version, version)
            # very likely the current version is the correct one
            # 
            # we must know explicitly what user intended to
            # even we have the specific version spec since
            # this is very likely to be rejected in General
            if prompt("do you want to release current version instead?"; require=true)
                version_number = version
            end
        else
            cmd_error("cannot release discontinous versions, please check your version in Project.toml")
        end
    else
        # current is older than latest version
        # this may because one wants to release
        # a patch/minor version of previous major
        # version, e.g
        # old versions: 1.1.0, 1.2.0
        # wants to release: 1.1.1
        println("your current version is smaller than latest release")

        print(" "^10, "current version: ")
        printstyled(version; color=:light_cyan)
        println()

        print(" "^10, "latest version: ")
        printstyled(latest_version; color=:light_cyan)
        println()

        prompt("are you sure to release this version?"; require=true) || cmd_exit()
    end
    return version_number
end

function should_update_version(project::ProjectToRelease)
    project.version_spec == "current" && return false
    project.release_version == project.version && return false
    return true
end

function update_version!(project::ProjectToRelease)
    prompt("do you want to update Project.toml?") || cmd_exit()
    write_version(project)
    print(" ")
    printstyled("✔"; color=:light_green)
    print("  Project.toml has been updated to ")
    printstyled(project.release_version; color=:light_cyan)
    println()
    return project
end

function is_version_continuously_greater(latest::VersionNumber, release::VersionNumber)
    release > latest || return false
    # patch release
    latest.major == release.major && latest.minor == release.minor &&
        latest.patch+1 == release.patch && return true

    # minor release
    latest.major == release.major && latest.minor+1 == release.minor &&
        latest.patch == release.patch && return true

    # major release
    latest.major+1 == release.major && latest.minor == release.minor &&
        latest.patch == release.patch && return true
    return false
end

function bump_version(::Nothing, token::String)
    return bump_version(v"0.0.0", token)
end

function bump_version(version::VersionNumber, token::String)
    if token == VERSION_TOKENS.major
        return VersionNumber(version.major+1, 0, 0)
    elseif token == VERSION_TOKENS.minor
        return VersionNumber(version.major, version.minor+1, 0)
    elseif token == VERSION_TOKENS.patch
        return VersionNumber(version.major, version.minor, version.patch+1)
    else
        cmd_error("invalid version spec $token")
    end
end

function write_version(project::ProjectToRelease)
    d = TOML.parsefile(project.toml)
    d["version"] = string(project.release_version)
    write_project_toml(project.toml, d)
    return
end

function commit_version_update(project::ProjectToRelease)
    @info "commit version updates" project
    cd(project.path) do
        redirect_stdout(devnull) do
            run(`$(git()) add $(project.toml)`)
            run(`$(git()) commit -m"bump version to $(project.release_version)"`)
        end
    end
end


"""
    PRN{name}

Package Registry Name
"""
struct PRN{name} end

"""
    PRN(name::String)

Create a `PRN` (Pacakge Registry Name) object.
"""
PRN(name::String) = PRN{Symbol(name)}()

macro PRN_str(name::String)
    return PRN{Symbol(name)}
end

Base.show(io::IO, ::PRN{registry}) where {registry} = print(io, "Pacakge Registry ", string(registry))

function register(registry::String, project::ProjectToRelease)
    registry = isempty(registry) ? determinte_register(project) : registry
    return register(PRN(registry), project)
end

function determinte_register(project::ProjectToRelease)
    info = find_package(project.name)
    if info === nothing
        if prompt(
                "package is not registered in local registries, " *
                "do you want to register it in the General registry?"
            )
            return "General"
        else
            cmd_exit()
        end
    else
        return info.reg.name
    end
end

function register(registry::PRN, project::ProjectToRelease)
    cmd_error("register workflow is not defined for $registry")
end

function register(::PRN"General", project::ProjectToRelease)
    @info "register package in General"
    auth_done = Base.Event()
    summon_done = Base.Event()
    interrupted_or_done = Base.Event()
    print_task = useless_animation(auth_done, summon_done, interrupted_or_done)

    @info "authenticating GitHub account"
    github_token = read_github_auth()
    auth = GitHub.authenticate(github_token)
    notify(auth_done)

    HEAD = get_head_sha256(project.path; project.branch)
    comment_json = Dict{String, Any}(
        "body" => julia_registrator_comment(project),
    )

    repo = github_repo(project.path)
    if repo === nothing
        cmd_error(
            "not a GitHub repository, registering " *
            "non-github packages is not supported, " *
            "please use JuliaHub instead"
        )
    end

    comment = GitHub.create_comment(repo, HEAD, :commit; params=comment_json, auth=auth)
    notify(summon_done)
    notify(interrupted_or_done)
    wait(print_task)

    print("\e[1G ")
    printstyled("✔"; color=:light_green)
    println("  JuliaRegistrator has been summoned, check it in the following URL:")
    printstyled("  ", comment.html_url; color=:cyan)
    return comment
end

function julia_registrator_comment(project::ProjectToRelease)
    lines = [
        "Released via [Ion](https://github.com/Roger-luo/Ion.jl)",
        "",
    ]
    cmd = ["@JuliaRegistrator", "register", "branch=$(project.branch)"]
    if project.subdir != "."
        push!(cmd, "subdir=$(project.subdir)")
    end
    push!(lines, join(cmd, " "))

    if !isempty(project.note)
        push!(lines, "")
        title = project.version_spec == "patch" ? "Patch notes:" : "Release notes:"
        push!(lines, title)
        push!(lines, project.note)
    end
    push!(lines, "")
    return join(lines, '\n')
end

function useless_animation(auth::Base.Event, summon::Base.Event, interrupted_or_done::Base.Event)
    anim_chars = ["◐","◓","◑","◒"]
    ansi_enablecursor = "\e[?25h"
    ansi_disablecursor = "\e[?25l"
    t = Timer(0; interval=1/20)
    print_lock = ReentrantLock()
    printloop_should_exit = interrupted_or_done.set
    return @async begin
        try
            count = 1
            while !printloop_should_exit
                lock(print_lock) do
                    print(ansi_disablecursor)
                    print("\e[1G  ")
                    printstyled(anim_chars[mod1(count, 4)]; color=:cyan)
                    print("    ")
                    if !auth.set
                        print("authenticating...")
                    elseif !summon.set
                        print("summoning JuliaRegistrator...")
                    else
                        printloop_should_exit = true
                    end
                end
                printloop_should_exit = interrupted_or_done.set
                count += 1
                wait(t)
            end
        catch e
            notify(interrupted_or_done)
            lock(print_lock) do
                println("\e[1G  ", RED_FG("❌"), "  fail to register $(project.pkg.name), error msg:")
                println(e.msg)
            end
            rethrow(e)
        finally
            print(ansi_enablecursor)
        end
    end
end
