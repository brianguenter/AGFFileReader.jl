# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.


# paths for GlassCat source file builds
const GLASSCAT_DIR = @__DIR__ # contains GlassCat.jl (pre-existing)
const SOURCES_PATH = joinpath(GLASSCAT_DIR, "sources.txt")


"""
    generate_jls(sourcenames::Vector{<:AbstractString}, mainfile::AbstractString, jldir::AbstractString, agfdir::AbstractString; test::Bool = false)

Generates .jl files in `jldir`: a `mainfile` and several catalog files.

Each catalog file is a module representing a distinct glass catalog (e.g. NIKON, SCHOTT), generated from corresponding
AGF files in `agfdir`. These are then included and exported in `mainfile`.

In order to avoid re-definition of constants `AGF_GLASS_NAMES` and `AGF_GLASSES` during testing, we have an optional
`test` argument. If `true`, we generate a .jl file that defines glasses with `GlassType.TEST` to avoid namespace/ID
clashes.
"""
function generate_jl(
    source::AbstractString,
    jldir::AbstractString,
    agfdir::AbstractString;
)

    # generate several catalog files (.jl)
    # parse the agffile (.agf) into a catalog (native Julia dictionary)
    agffile = joinpath(agfdir, "$(source).agf")
    catalog = agffile_to_catalog(agffile)

    # parse the catalog into a module string and write it to a catalog file (.jl)
    modstring = catalog_to_modstring(source, catalog)
    catalogpath = joinpath(jldir, source * ".jl")
    @info "Writing $catalogpath"
    open(catalogpath, "w") do io
        write(io, modstring)
    end
end

"""
Parse a `agffile` (.agf) into a native Dict, `catalogdict`, where each `kvp = (glassname, glassinfo)` is a glass.

| 1  | 2        | 3         | 4     | 5     | 6                     | 7             | 8         | 9         | 10    | 11    |
|:---|:---------|:----------|:------|:------|:----------------------|:--------------|:----------|:----------|:------|:------|
| NM | raw name | dispform  | ?     |  Nd   | Vd                    | [exclude_sub  | status    | meltfreq] |
| ED | TCE      | ?         | p     |  ΔPgF | [ignore_thermal_exp]  |
| CD | C1       | C2        | C3    |  C4   | C5                    | C6            | C7        | C8        | C9    | C10   |
| TD | D₀       | D₁        | D₂    |  E₀   | E₁                    | λₜₖ           | temperature      |
| OD | relcost  | CR        | FR    |  SR   | AR                    | PR
| LD | λmin     | λmax      |
| IT | T1       | T2        | T3    |
"""
function agffile_to_catalog(agffile::AbstractString)
    catalogdict = Dict{String,Dict{String}}()

    # store persistent variables between loops
    glassname = ""
    rowbuffer = []

    # `rowspecs` provides tuples (keys, defaultvalues) which describe how to parse each tokenized row
    nullspec = ("", [])
    rowspecs = Dict(
        "CC" => nullspec,
        "GC" => nullspec,
        "NM" => (
            "raw_name dispform _        Nd   Vd   exclude_sub status meltfreq",
            [nothing, NaN, nothing, NaN, NaN, 0, 0, 0]
        ),
        "ED" => (
            "TCE  _        p    ΔPgF ignore_thermal_exp",
            [NaN, nothing, NaN, NaN, 0]
        ),
        "CD" => (
            join([string('C', i) for i in 1:10], ' '),
            repeat([NaN], 10)
        ),
        "TD" => (
            "D₀ D₁ D₂ E₀ E₁ λₜₖ temperature",
            [0, 0, 0, 0, 0, 0, 20]
        ),
        "OD" => (
            "relcost CR FR SR AR PR",
            repeat([-1], 6)
        ),
        "LD" => (
            "λmin λmax",
            [NaN, NaN]
        ),
        "IT" => nullspec,
    )

    # call process_rowbuffer!() when rowbuffer is a vector corresponding to a full AGF row
    # e.g. rowbuffer = ["OD", -1.0, 5.0, 5.0, 5.0, -1.0, -1.0]
    # the function will parse the row data into catalogdict and flush the row buffer
    function process_rowbuffer!()
        # an empty rowbuffer gets passed at the beginning of each file
        if isempty(rowbuffer)
            return
        end
        token = rowbuffer[1]

        # NM and IT need special treatment
        if token == "NM"
            glassname = make_valid_name(string(rowbuffer[2]))
            catalogdict[glassname] = Dict{String,Any}()
            catalogdict[glassname]["transmission"] = Vector{SVector{3,Float64}}(undef, 0)
        elseif token == "IT"
            if rowbuffer[2] != 0 && length(rowbuffer) == 4
                push!(catalogdict[glassname]["transmission"], SVector{3,Float64}(rowbuffer[2:4]))
            end
        end

        if token ∉ keys(rowspecs)
            # unrecognized token: treat the row as a comment (ignore)
            token = "CC"
        end
        rowspec = rowspecs[token]

        # parse row buffer into catalogdict, according to rowspec
        for (i, (key, defaultvalue)) in enumerate(zip(split(rowspec[1]), rowspec[2]))
            value = length(rowbuffer) < i + 1 || rowbuffer[i+1] == "-" ? defaultvalue : rowbuffer[i+1]
            catalogdict[glassname][key] = value
        end

        # flush rowbuffer
        rowbuffer = []
    end

    is_utf8 = isvalid(readuntil(agffile, " "))
    # use DelimitedFiles.readdlm to parse the source file conveniently (with type inference)
    for line in eachrow(readdlm(agffile))
        for item in line
            if !is_utf8
                item = decode(Vector{UInt8}(item), "UTF-16")
                _item = tryparse(Float64, item)
                item = _item === nothing ? item : _item
            end

            if item == "" # eol
                break
            elseif item ∈ keys(rowspecs) # process buffer when a token is reached, instead of at eol (see Issue #106)
                process_rowbuffer!()
            end

            push!(rowbuffer, item)
        end
    end
    process_rowbuffer!()

    return catalogdict
end

"""
Make a valid Julia variable name from an arbitrary string.
"""
function make_valid_name(name::AbstractString)
    # remove invalid characters
    name = replace(name, "*" => "_STAR")
    name = replace(name, r"""[ ,.:;?!()&-]""" => "_")
    # cant have module names which are just numbers so add a _ to the start
    if tryparse(Int, "$(name[1])") !== nothing
        name = "_" * name
    end
    return name
end

"""
Convert a `catalog` dict into a `modstring` which can be written to a Julia source file.
"""
function catalog_to_modstring(
    catalogname::AbstractString, catalog::Dict{<:AbstractString}
)
    isCI = haskey(ENV, "CI")

    modstrings = [
        "module $catalogname",
        "using ..AGFFileReader: Glass",
        "export $(join(keys(catalog), ", "))",
        ""
    ]
    for (glassname, glassinfo) in catalog
        argstring = glassinfo_to_argstring(glassinfo)
        push!(modstrings, "const $glassname = Glass($argstring)")
    end
    append!(modstrings, ["end # module", ""]) # last "" is for \n at EOF

    return join(modstrings, "\n")
end

"""
Convert a `glassinfo` dict into a `docstring` to be prepended to a `Glass` const.
"""
function glassinfo_to_docstring(
    glassinfo::Dict{<:AbstractString},
    catalogname::AbstractString,
    glassname::AbstractString,
)
    raw_name = glassinfo["raw_name"] == glassname ? "" : " ($(glassinfo["raw_name"]))"
    pad(str, padding=25) = rpad(str, padding)
    getinfo(key, default=0.0) = get(glassinfo, key, default)

    return join([
            "\"\"\"    $catalogname.$glassname$raw_name",
            "```",
            "$(pad("RI @ 587nm:"))$(getinfo("Nd"))",
            "$(pad("Abbe Number:"))$(getinfo("Vd"))",
            "$(pad("ΔPgF:"))$(getinfo("ΔPgF"))",
            "$(pad("TCE (÷1e-6):"))$(getinfo("TCE"))",
            "$(pad("Density:"))$(getinfo("p"))g/m³",
            "$(pad("Valid wavelengths:"))$(getinfo("λmin"))μm to $(getinfo("λmax"))μm",
            "$(pad("Reference Temp:"))$(getinfo("temperature", 20.0))°C",
            "```",
            "\"\"\""
        ], "\n")
end

"""
Convert a `glassinfo` dict into an `argstring` to be passed into a `Glass` constructor.
"""
function glassinfo_to_argstring(glassinfo::Dict{<:AbstractString})
    argstrings = []
    for fn in string.(fieldnames(Glass))
        if fn in ["D₀", "D₁", "D₂", "E₀", "E₁", "λₜₖ"]
            push!(argstrings, repr(get(glassinfo, fn, 0.0)))
        elseif fn == "temperature"
            push!(argstrings, repr(get(glassinfo, fn, 20.0)))
        elseif fn == "transmission"
            v = get(glassinfo, "transmission", nothing)
            if v === nothing
                push!(argstrings, repr(nothing))
            else
                str = join(["($(join(a, ", ")))" for a in v], ", ")
                push!(argstrings, "[$str]")
            end
        elseif fn == "relcost"
            cost = get(glassinfo, fn, -1)
            if isa(cost, String) #some glass files use "_" to mean there is no relcost value. SCHOTT does this.
                push!(argstrings, repr(-1))
            else
                push!(argstrings, repr(cost))
            end
        elseif fn == "transmissionN"
            continue
        else
            push!(argstrings, repr(get(glassinfo, fn, NaN)))
        end
    end
    return join(argstrings, ", ")
end


function download_AGF_files()
    global DATA_DIR = @get_scratch!(SCRATCH_NAME)

    agf_dir = mkpath(joinpath(DATA_DIR, "agf"))
    jl_dir = mkpath(joinpath(DATA_DIR, "jl"))

    # Build/verify a source directory using information from sources.txt
    sources = split.(readlines(SOURCES_PATH))

    verify_sources!(sources, agf_dir)
    verified_source_names = first.(sources)

    # Use verified sources to generate required .jl files
    @info "Using sources: $(join(verified_source_names, ", ", " and "))"
    for source in verified_source_names
        @info "Generating jl file for $source"
        generate_jl(source, jl_dir, agf_dir)
    end

    # generate the parent main file (.jl)
    agfstrings = [
        "export $(join(verified_source_names, ", "))",
        "",
        ["include(raw\"$(joinpath(jl_dir,(source)* ".jl"))\")" for source in verified_source_names]...,
        "",
        "const AGF_GLASSES = [$(join(verified_source_names, ", "))]",
        ""
    ]
    glass_cat = joinpath(jl_dir, "AGFGlassCat.jl")
    @info "Writing $glass_cat)"
    open(glass_cat, "w") do io
        write(io, join(agfstrings, "\n"))
    end
end
export download_AGF_files

#TODO
function add_AGF_file()
    global data_dir = @get_scratch!(SCRATCH_NAME)
    throw(ErrorException("not implemented"))
end

function clear_AGF_files()
    if ispath(DATA_DIR)
        rm(joinpath(DATA_DIR, "agf"), recursive=true)
        rm(joinpath(DATA_DIR, "jl"), recursive=true)
    end
end
export clear_AGF_files