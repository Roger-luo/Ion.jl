using Ion
using Documenter

DocMeta.setdocmeta!(Ion, :DocTestSetup, :(using Ion); recursive=true)

makedocs(;
    modules=[Ion],
    authors="Roger-Luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Ion.jl/blob/{commit}{path}#{line}",
    sitename="Ion.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Ion.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Ion.jl",
)
