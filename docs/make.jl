using AGFFileReader
using Documenter

DocMeta.setdocmeta!(AGFFileReader, :DocTestSetup, :(using AGFFileReader); recursive=true)

#TODO add plotting examples

makedocs(;
    modules=[AGFFileReader],
    authors="rambunctiousapple",
    repo="https://github.com/rambunctiousapple/AGFFileReader.jl/blob/{commit}{path}#{line}",
    sitename="AGFFileReader.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rambunctiousapple.github.io/AGFFileReader.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/rambunctiousapple/AGFFileReader.jl.git",
    devbranch="main",
    push_preview = true,
)
