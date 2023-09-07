using Exams
using Documenter

DocMeta.setdocmeta!(Exams, :DocTestSetup, :(using Exams); recursive=true)

makedocs(;
    modules=[Exams],
    authors="Javier Principe",
    repo="https://github.com/principejavier/Exams.jl/blob/{commit}{path}#{line}",
    sitename="Exams.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://principejavier.github.io/Exams.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

# deploydocs(;
#     repo="github.com/principejavier/Exams.jl",
#     devbranch="main",
# )
