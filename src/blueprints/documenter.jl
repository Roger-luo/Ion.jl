@option struct Documenter
    assets::Vector{String}
    # logo should be user input from interface
    make_jl::String # make.jl template
    index_md::String # index.md template
    devbranch::Maybe{String} # if nothing use default branch
end

function compile(bp::Documenter, ctx::Context)
end
