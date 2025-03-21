# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

using Test
using TestItems
using TestItemRunner
using AGFFileReader

using Base.Filesystem
using DataFrames: DataFrame
using StaticArrays
using Unitful
using Unitful.DefaultSymbols




@run_package_tests

include("Aqua.jl")

@testsnippet WrappedAllocs begin
    """
        @wrappedallocs(expr)
    https://github.com/JuliaAlgebra/TypedPolynomials.jl/blob/master/test/runtests.jl
    
    Given an expression, this macro wraps that expression inside a new function
    which will evaluate that expression and measure the amount of memory allocated
    by the expression. Wrapping the expression in a new function allows for more
    accurate memory allocation detection when using global variables (e.g. when
    at the REPL).
    For example, `@wrappedallocs(x + y)` produces:
    ```julia
    function g(x1, x2)
        @allocated x1 + x2
    end
    g(x, y)
    ```
    You can use this macro in a unit test to verify that a function does not
    allocate:
    ```
    @test @wrappedallocs(x + y) == 0
    ```
    """
    macro wrappedallocs(expr)
        argnames = [gensym() for a in expr.args]
        quote
            function g($(argnames...))
                @allocated $(Expr(expr.head, argnames...))
            end
            $(Expr(:call, :g, [esc(a) for a in expr.args]...))
        end
    end
end

@testsnippet Add_AGF begin
    tmpdir = mktempdir()
    agfdir = mktempdir(tmpdir)
    sourcefile, _ = mktemp(tmpdir)
end
@testitem "bad implicit catalog names" setup = [Add_AGF] begin
    for agffile in split("a 1.agf a.Agf")
        @test_logs (:error, "invalid implicit catalog name \"$agffile\". Should be purely alphabetical with a .agf/.AGF extension.") add_agf(agffile; agfdir, sourcefile)
    end
end

# Currently do not have a reasonable way to add agf files. Need to rework all the code that downloads the AGF files and converts them to source.
# @testitem "add to source file" setup = [Add_AGF] begin
#     for name in split("a b")
#         open(joinpath(tmpdir, "$name.agf"), "w") do io
#             write(io, "")
#         end
#     end
#     empty_sha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

#     @test isempty(readlines(sourcefile))

#     add_agf(joinpath(tmpdir, "a.agf"); agfdir, sourcefile, rebuild=false)
#     @test length(readlines(sourcefile)) === 1
#     @test readlines(sourcefile)[1] === "A $empty_sha"

#     add_agf(joinpath(tmpdir, "b.agf"); agfdir, sourcefile, rebuild=false)
#     @test length(readlines(sourcefile)) === 2
#     @test readlines(sourcefile)[1] === "A $empty_sha"
#     @test readlines(sourcefile)[2] === "B $empty_sha"

#     @test_logs(
#         (:error, "adding the catalog name \"A\" would create a duplicate entry in source file $sourcefile"),
#         add_agf(joinpath(tmpdir, "a.agf"); agfdir, sourcefile)
#     )
# end

# TODO rebuild=true

# integration test
@testitem "verify_sources!" begin
    tmpdir = mktempdir()
    agfdir = mktempdir(tmpdir)

    sources = split.(readlines(AGFFileReader.SOURCES_PATH))
    AGFFileReader.verify_sources!(sources, agfdir)

    # this doesn't work if any of the glass catalogs can't be downloaded. Need a different test
    # @test first.(sources) == first.(split.(readlines(AGFFileReader.SOURCES_PATH)))

    # TODO missing_sources
end


@testsnippet Generate begin
    using DataFrames

    CATALOG_NAME = "TEST_CAT"
    SOURCE_DIR = @__DIR__
    SOURCE_FILE = joinpath(SOURCE_DIR, "$(CATALOG_NAME).agf")

    TMP_DIR = mktempdir()
    MAIN_FILE = joinpath(TMP_DIR, "AGF_TEST_CAT.jl")

    TEST_CAT_VALUES = DataFrame(
        name=split("MG463_ MG523 _5MG448 MG452_STAR"),
        raw_name=split("MG463& MG523 5MG448 MG452*"),
        dispform=repeat([2], 4),
        Nd=repeat([1.0], 4),
        Vd=repeat([0.0], 4),
        exclude_sub=[5, 0, 0, 0],
        status=[6, 0, 0, 0],
        meltfreq=repeat([-1], 4),
        TCE=[19.8, 18.3, 30.2, 25.7],
        p=[4.63, 5.23, 4.48, 4.52],
        ΔPgF=repeat([0.0], 4),
        ignore_thermal_exp=[3, 0, 0, 0],
        C1=[6.781409960E+00, 4.401393677E+00, 8.427948454E+00, 4.656568861E+00],
        C2=[9.868538020E-02, 2.234722960E-02, 6.325268390E-02, 1.170534894E-01],
        C3=[3.469529960E-03, 4.562935070E+00, -2.441576539E+00, 1.409322578E+00],
        C4=[2.277823700E+00, 3.239318260E-01, 1.997453950E-03, 2.445302672E-04],
        C5=[2.126055280E+00, 6.863473749E-01, 4.975938104E-01, 6.352738622E-01],
        C6=[3.227490100E+03, 1.625888344E+03, 1.443307391E+03, 1.397305161E+03],
        C7=repeat([0.0], 4),
        C8=repeat([0.0], 4),
        C9=repeat([0.0], 4),
        C10=repeat([0.0], 4),
        D₀=[2.226000000E-05, 1.122401430E-04, -1.718689957E-05, -2.545621409E-07],
        D₁=[5.150100000E-08, 2.868995096E-13, -6.499841076E-13, 1.258087492E-10],
        D₂=[1.309700000E-10, -4.157332734E-16, -4.153311088E-16, 1.119703940E-11],
        E₀=[4.382400000E-05, 9.532969159E-05, 8.220254442E-06, 2.184273853E-05],
        E₁=[4.966000000E-07, -1.045247704E-11, 6.086168578E-12, -2.788674395E-09],
        λₜₖ=[3.728000000E-01, 6.338475915E-01, 3.610058073E-01, -1.948154058E+00],
        temperature=[2.002000000E+01, 2.000000000E+01, 2.000000000E+01, 2.000000000E+01],
        relcost=[1.1, -1.0, -1.0, -1.0],
        CR=[1.2, -1.0, -1.0, -1.0],
        FR=[1.3, -1.0, -1.0, -1.0],
        SR=[1.4, -1.0, -1.0, -1.0],
        AR=[1.5, -1.0, -1.0, -1.0],
        PR=[1.6, -1.0, -1.0, -1.0],
        λmin=repeat([2.0], 4),
        λmax=repeat([14.0], 4),
        transmission=[
            [[2.0, 1.0, 3.0], [14.0, 4.0, 5.0]],
            [[2.0, 1.0, 1.0], [14.0, 1.0, 1.0]],
            [[2.0, 1.0, 1.0], [14.0, 1.0, 1.0]],
            [[2.0, 1.0, 1.0], [14.0, 1.0, 1.0]],
        ],
    )
    FIELDS = names(TEST_CAT_VALUES)[2:end]
end
@testitem "Parsing Tests" setup = [Generate] begin
    cat = AGFFileReader.agffile_to_catalog(SOURCE_FILE)

    for glass in eachrow(TEST_CAT_VALUES)
        name = glass["name"]
        @test name ∈ keys(cat)
        for field in FIELDS
            @test glass[field] == cat[name][field]
        end
    end
end

@testitem "Glass Tests" setup = [WrappedAllocs] begin
    using Unitful
    using Unitful.DefaultSymbols

    @test absairindex(500nm) ≈ 1.0002741948670688 atol = 1e-14
    @test absairindex(600nm, temperature=35°C, pressure=2.0) ≈ 1.0005179096900811 atol = 1e-14
    @test index(Air, 500nm) == 1.0
    @test index(Air, 600nm) == 1.0

    # test against true values
    g = Examples_N_BK7
    @test index(g, 533nm) ≈ 1.519417351519283 atol = 1e-14
    @test index(g, 533nm, temperature=35°C) ≈ 1.519462486258311 atol = 1e-14
    @test index(g, 533nm, pressure=2.0) ≈ 1.518994119690216 atol = 1e-14
    @test index(g, 533nm, temperature=35°C, pressure=2.0) ≈ 1.519059871499476 atol = 1e-14

    # test transmission
    @test absorption(Air, 500nm) == 0.0
    @test absorption(Air, 600nm) == 0.0
    # TODO these are currently taken from this package (i.e. regression tests), ideally we would get true values somehow
    @test absorption(g, 500nm) == 0.0002407228930225164
    @test absorption(g, 600nm) == 0.00022060722752440445
    @test absorption(g, 3000nm) == 0.04086604990127926
    @test absorption(g, 600nm, temperature=35°C, pressure=2.0) == 0.00022075540719494738

    # test that everything is alloc-less
    @test (@wrappedallocs absorption(g, 600nm)) == 0
    @test (@wrappedallocs index(g, 533nm)) == 0
    @test (@allocated Examples_N_BK7) == 0


    @test isair(Air) == true
    @test isair(Examples_N_BK7) == false

    # test MIL and model glasses
    fit_acc = 0.001
    bk7 = glassfromMIL(517642)
    @test index(bk7, 0.5875618) ≈ 1.517 atol = fit_acc
    @test index(bk7, 0.533) ≈ 1.519417351519283 atol = fit_acc
    @test index(bk7, 0.743) ≈ 1.511997032563557 atol = fit_acc
    @test index(bk7, 533nm, temperature=35°C, pressure=2.0) ≈ 1.519059871499476 atol = fit_acc

    t2 = glassfromMIL(1.135635)
    @test index(t2, 0.5875618) ≈ 2.135 atol = fit_acc

    fit_acc = 0.0001
    bk7 = modelglass(1.5168, 64.167336, -0.0009)
    @test index(bk7, 0.5875618) ≈ 1.5168 atol = fit_acc
    @test index(bk7, 0.533) ≈ 1.519417351519283 atol = fit_acc
    @test index(bk7, 0.743) ≈ 1.511997032563557 atol = fit_acc
    @test index(bk7, 533nm, temperature=35°C, pressure=2.0) ≈ 1.519059871499476 atol = fit_acc

    # test other glass
    @test index(CARGILLE.OG0608, 0.578) == 1.4596475735607324

    # make sure that the other functions work
    # plot_indices(SCHOTT.N_BK7; polyfit = true, fiterror = true) #this causes error on github actions. Can't load graphics library for headless operation.
end

@testitem "Air.jl" begin
    @test repr(Air) === "Air"
    @test glassname(Air) === "AGFFileReader.Air"

    info_lines = [
        "AGFFileReader.Air",
        "Material representing air, RI is always 1.0 at system temperature and pressure, absorption is always 0.0.",
        ""
    ]
    io = IOBuffer()
    info(io, Air)
    @test String(take!(io)) === join(info_lines, '\n')
end

@testitem "GlassTypes.jl" begin



    info_lines = [
        "Dispersion formula:                                Cauchy (-2)",
        "Dispersion formula coefficients:",
        "     A:                                            1.44503",
        "     B:                                            0.0044096",
        "     C:                                            -2.85878e-5",
        "     D:                                            0.0",
        "     E:                                            0.0",
        "     F:                                            0.0",
        "Valid wavelengths:                                 0.32μm to 1.55μm",
        "Reference temperature:                             25.0°C",
        "Thermal ΔRI coefficients:",
        "     D₀:                                           -0.0009083144750540808",
        "     D₁:                                           0.0",
        "     D₂:                                           0.0",
        "     E₀:                                           0.0",
        "     E₁:                                           0.0",
        "     λₜₖ:                                          0.0",
        "TCE (÷1e-6):                                       700.0",
        "Ignore thermal expansion:                          false",
        "Density (p):                                       0.878g/m³",
        "ΔPgF:                                              0.008",
        "RI at sodium D-Line (587nm):                       1.457587",
        "Abbe Number:                                       57.19833",
        "Cost relative to N_BK7:                            ?",
        "Status:                                            Standard (0)",
        "Melt frequency:                                    ?",
        "Exclude substitution:                              false",
        "Transmission data:",
        "     Wavelength   Transmission      Thickness",
        "         0.32μm           0.15         10.0mm",
        "        0.365μm           0.12        100.0mm",
        "       0.4047μm           0.42        100.0mm",
        "         0.48μm           0.78        100.0mm",
        "       0.4861μm           0.79        100.0mm",
        "       0.5461μm           0.86        100.0mm",
        "       0.5893μm            0.9        100.0mm",
        "       0.6328μm           0.92        100.0mm",
        "       0.6439μm            0.9        100.0mm",
        "       0.6563μm           0.92        100.0mm",
        "       0.6943μm           0.98        100.0mm",
        "         0.84μm           0.99        100.0mm",
        "      0.10648μm           0.61        100.0mm",
        "         0.13μm           0.39        100.0mm",
        "        0.155μm           0.11        100.0mm",
        ""
    ]
    io = IOBuffer()
    info(io, CARGILLE.OG0607)
    @test String(take!(io)) === join(info_lines, '\n')

    # TODO the rest of the string tests
end

@testitem "search.jl" begin
    #this test set doesn't work as is. It assumes that all the glass catalogs have downloaded correctly which may not happen. Commenting them all out till we figure out a better set of tests.

    # @test glasscatalogs() == [
    #     CARGILLE,
    #     HOYA,
    #     NIKON,
    #     OHARA,
    #     SCHOTT,
    #     SUMITA,
    # ]

    # @test glassnames(CARGILLE) == [
    #     :OG0607,
    #     :OG0608,
    #     :OG081160,
    # ]

    # @test first.(glassnames()) == [
    #     CARGILLE,
    #     HOYA,
    #     NIKON,
    #     OHARA,
    #     SCHOTT,
    #     SUMITA,
    # ]
    # @test length.(last.(glassnames())) == [
    #     3,
    #     210,
    #     379,
    #     160,
    #     160,
    #     178,
    # ]

    # @test findglass(x -> (x.Nd > 2.1 && x.λmin < 0.5 && x.λmax > 0.9)) == [
    #     HOYA.E_FDS3,
    #     SUMITA.K_PSFn214P,
    #     SUMITA.K_PSFn214P_M_,
    # ]

    # TODO _child_modules() unit test
end
