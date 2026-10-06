using Documenter
using GameTCAgentsBR

makedocs(;
    modules = [GameTCAgentsBR],
    sitename = "GameTCAgentsBR.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://yamanori99.github.io/GameTCAgentsBR.jl",
        edit_link = "main",
    ),
    pages = [
        "API" => "index.md",
    ],
    checkdocs = :none,
    warnonly = [:missing_docs],
)

deploydocs(;
    repo = "github.com/yamanori99/GameTCAgentsBR.jl.git",
    devbranch = "main",
    push_preview = false,
    versions = ["dev" => "dev"],
)
