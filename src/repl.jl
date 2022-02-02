for api in [:release, :clone, :compat]
    @eval function $api(args...; kw...)
        try
            Internal.$api(args...; kw...)
        catch e
            if e isa Comonicon.CommandExit
                return e.exitcode
            else
                rethrow(e)
            end
        end
    end
end
