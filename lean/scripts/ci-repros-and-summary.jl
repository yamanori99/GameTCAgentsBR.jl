# CI: run lean/repro/*.jl and write $GITHUB_STEP_SUMMARY (registry + refuted table).

const REPRO_DIR = joinpath(@__DIR__, "..", "repro")
const PROJECT_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const REGISTRY = joinpath(@__DIR__, "..", "registry.tsv")
const REFUTED_MAP = joinpath(@__DIR__, "refuted-reproducers.tsv")
const BUGS_DIR = joinpath(@__DIR__, "..", "bugs")

function parse_registry(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && return String[], []
    header = split(lines[1], '\t')
    rows = []
    for line in lines[2:end]
        cols = split(line, '\t')
        row = Dict(zip(header, cols))
        push!(rows, row)
    end
    return header, rows
end

function parse_refuted_map(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && return Dict{String, Tuple{String, String}}()
    mapping = Dict{String, Tuple{String, String}}()
    for line in lines[2:end]
        id, repro, expected = split(line, '\t')
        mapping[id] = (repro, expected)
    end
    return mapping
end

function bug_meta(id)
    aliases = Dict(
        "float-eps-equals-rational-argmax" => "rational-vs-float-br-eps-larger",
        "pairgame-128-runtime" => "pairgame-128-strategies",
        "group-a-size-float-rational" => "group-a-size-rational-mismatch",
        "group-a-size-halfup-equals-julia" => "group-a-size-float-mismatch",
    )
    stem = get(aliases, id, id)
    yaml_path = joinpath(BUGS_DIR, "$(stem).yaml")
    isfile(yaml_path) || return (priority = "—", pr15 = false)
    txt = read(yaml_path, String)
    pr15 = occursin("pr15_note:", txt)
    m = match(r"^priority:\s*(\S+)", txt)
    if m !== nothing
        priority = m[1]
    else
        m2 = match(r"^severity:\s*(\S+)", txt)
        priority = m2 === nothing ? "—" : m2[1]
    end
    return (priority = priority, pr15 = pr15)
end

function pr15_from_note(note)
    return occursin("PR #15", note) || occursin("pr15", lowercase(note))
end

function run_repro(path)
    repro = basename(path)
    cmd = addenv(
        `julia --project=$PROJECT_ROOT $path`,
        "LEAN_BUG_HUNT_CI" => get(ENV, "LEAN_BUG_HUNT_CI", ""),
    )
    combined = try
        io = IOBuffer()
        proc = run(pipeline(cmd, stdout = io, stderr = io), wait = true)
        if proc.exitcode != 0
            return (repro, "error", String(take!(io)), "")
        end
        String(take!(io))
    catch e
        return (repro, "error", sprint(show, e), "")
    end
    return (repro, "ok", combined, "")
end

function main()
    _, registry = parse_registry(REGISTRY)
    refuted_map = parse_refuted_map(REFUTED_MAP)
    repro_files = sort(filter(f -> endswith(f, ".jl"), readdir(REPRO_DIR)))
    repro_results = Dict{String, Tuple{String, String}}()
    failures = String[]
    drift = String[]
    refuted_repros = Set(values(refuted_map) .|> first)

    for f in repro_files
        path = joinpath(REPRO_DIR, f)
        repro, status, out, err = run_repro(path)
        combined = out * err
        repro_results[f] = (status, combined)
        if status != "ok" && !(f in refuted_repros)
            push!(failures, "$f: julia exit non-zero")
        end
    end

    for (rid, (repro, expected)) in refuted_map
        haskey(repro_results, repro) || begin
            push!(drift, "$rid: missing repro $repro")
            continue
        end
        _, combined = repro_results[repro]
        if !occursin(expected, combined)
            push!(drift, "$rid: expected `$expected` in output of $repro")
        end
    end

    counts = Dict("proven" => 0, "refuted" => 0, "todo" => 0)
    for row in registry
        s = row["status"]
        counts[s] = get(counts, s, 0) + 1
    end

    summary_path = get(ENV, "GITHUB_STEP_SUMMARY", "")
    io = summary_path == "" ? stdout : open(summary_path, "w")
    try
        println(io, "## Lean bug hunt (registry)")
        println(io)
        println(io, "| Status | Count |")
        println(io, "|--------|------:|")
        for s in ("proven", "refuted", "todo")
            println(io, "| $s | $(counts[s]) |")
        end
        println(io)
        println(io, "### Refuted properties")
        println(io)
        println(io, "| id | Julia | severity | repro | PR #15 |")
        println(io, "|----|-------|----------|-------|--------|")
        for row in registry
            row["status"] == "refuted" || continue
            id = row["id"]
            jf = row["juliaFile"]
            note = get(row, "note", "—")
            meta = bug_meta(id)
            priority = meta.priority != "—" ? meta.priority : "—"
            pr15 = meta.pr15 || pr15_from_note(note) ? "yes" : "—"
            repro_status = "—"
            if haskey(refuted_map, id)
                repro, expected = refuted_map[id]
                if haskey(repro_results, repro)
                    st, combined = repro_results[repro]
                    repro_status = st == "error" ? "**error**" :
                        (occursin(expected, combined) ? "reproduced" : "**drift**")
                end
            elseif id == "int8-accepts-128"
                repro_status = "Lean only"
            end
            println(io, "| `$id` | `$jf` | $priority | $repro_status | $pr15 |")
        end
        println(io)
        println(io, "<details><summary>All registry entries ($(length(registry)))</summary>")
        println(io)
        println(io, "| id | status | file | note |")
        println(io, "|----|--------|------|------|")
        for row in registry
            println(io, "| `$(row["id"])` | $(row["status"]) | `$(row["juliaFile"])` | $(row["note"]) |")
        end
        println(io, "</details>")
        println(io)
        println(io, "### Reproducer scripts")
        println(io)
        println(io, "| script | result |")
        println(io, "|--------|--------|")
        for f in repro_files
            st, _ = repro_results[f]
            mark = st == "ok" ? "ok" : "**FAIL**"
            println(io, "| `$f` | $mark |")
        end
    finally
        summary_path != "" && close(io)
    end

    if !isempty(drift)
        foreach(d -> (@warn d), drift)
        error("Refuted entries no longer reproduced: $(join(drift, "; "))")
    end
    if !isempty(failures)
        error("Reproducers failed: $(join(failures, "; "))")
    end
    return println("ci-repros-and-summary.jl OK")
end

main()
