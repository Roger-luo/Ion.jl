module Option

using Configurations

@option struct Plugins
    template::Vector{String} = String[]
    registry::Vector{String} = String[]
end

@option struct Ion
    username::Maybe{String}
    default_template::String = "basic"
    templates::Dict{String, String} = Dict{String, String}(
        "basic" => templates("basic.toml"),
        "package" => templates("package.toml"),
        "academic" => templates("academic.toml"),
        "comonicon" => templates("comonicon.toml"),
        "comonicon-sysimg" => templates("comonicon-sysimg.toml"),
    )
end

end
