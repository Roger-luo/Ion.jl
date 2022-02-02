function test(project::String, suite_pattern::Vector{String}; coverage::Bool=false, startup_file::Bool=false, nprocs::Int=1)
    patterns = FilenameMatch.(suite_pattern)
    suites = find_test_suites(project) do suite
        isempty(suite_pattern) && return true
        any(p->ismatch(p, suite), patterns)
    end
    suites = divide_tests(suites, nprocs)
    results = pmap(run_test_suites, suites)

    print(err)
    print(report)
    return
end

function setup_test_process(project, nprocs::Int)
    test_dir(project)
    addprocs(nprocs;exeflags=["--project"])
end

function create_shared_env(project::String)
    pkgspec = PackageSpec(path=project)
    ctx = Context(env=EnvCache(project))
    TestEnv.isinstalled!(ctx, pkgspec) || throw(TestEnv.TestEnvError("$pkg not installed 👻"))
    Pkg.instantiate(ctx)
end

function divide_tests(suites::Dict{String, String}, nprocs::Int)
    suites_procs = [Dict{String, String}() for _ in 1:nprocs]
    
    n, r = divrem(length(suites), nprocs)
    nsuites_procs = [n for _ in 1:nprocs]
    if !iszero(r)
        for idx in 1:r
            nsuites_procs[idx] += 1
        end
    end

    proc_idx = 1; count = 0
    for (name, path) in suites
        suites_procs[proc_idx][name] = path
        count += 1

        if count == nsuites_procs[proc_idx]
            proc_idx += 1
            count = 0
        end
    end
    return suites_procs
end

function run_test_suites(suites::Dict{String, String})
    old_stdout, old_stderr = stdout, stderr
    # see https://github.com/JuliaLang/julia/issues/43586
    stdout_buf = IOContext(Pipe(), :color=>Base.get_have_color())
    stderr_buf = IOContext(Pipe(), :color=>Base.get_have_color())
    redirect_stdout(stdout_buf)
    redirect_stderr(stderr_buf)
    stdout_reader = @async read(stdout_buf, String)
    stderr_reader = @async read(stderr_buf, String)

    local err
    try
        for (suite, path) in suites
            eval_in_workspace(suite, path)
        end
    catch err
    finally
        redirect_stdout(old_stdout)
        redirect_stderr(old_stderr)
        close(stdout_buf)
        close(stderr_buf)
    end
    return fetch(stdout_reader), fetch(stderr_reader), err
end

function eval_in_workspace(name::String, path::String)
    m = Core.eval(Base.__toplevel__, :(module $(Symbol(path)) end))
    return Core.eval(m, 
        Expr(:toplevel,
            :(using Test),
            :(eval(x) = $(Expr(:core, :eval))($m, x)),
            :(include(x) = $(Expr(:top, :include))($m, x)),
            :(include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $m, x)),
            :(Test.@testset $name begin
                include($path)
            end)
        )
    )
end

function find_test_suites(f, project::String)
    test_suites = suites = Dict{String, String}()
    project_test_dir = test_dir(project)
    for (root, dirs, files) in walkdir(project_test_dir)
        if root != project_test_dir
            prefix = relpath(root, project_test_dir) * "/"
        else
            prefix = ""
        end
        for file in files
            startswith(file, "test_") || continue
            endswith(file, ".jl") || continue

            suite_name = prefix * file[6:end-3]
            f(suite_name) || continue
            suites[suite_name] = joinpath(root, file)
        end
    end
    return test_suites
end

test_dir(project::String, paths::String...) = joinpath(project, "test", paths...)
