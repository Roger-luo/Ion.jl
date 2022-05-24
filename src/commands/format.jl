"""
    format(path::String=pwd())

Run formatter at `path`, the `.JuliaFormatter.toml`
should be used to config the formatter.

# Args

- `path`: path to the folder/file to format.
"""
@cast function format(path::String=pwd())
    JuliaFormatter.format(path)
    return
end
