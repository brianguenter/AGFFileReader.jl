# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

module AGFFileReader

using Scratch
using Unitful
using StaticArrays
using Base: @.
import Unitful: Length, Temperature, Quantity, Units
using Unitful.DefaultSymbols
using DelimitedFiles

using DelimitedFiles: readdlm # used in agffile_to_catalog

#scratch data directory to store glass files

scratch_directory() = @get_scratch!("GlassData")
agf_directory() = joinpath(scratch_directory(), "agf")
jl_directory() = joinpath(scratch_directory(), "jl")
"""Download AGF glass files from list in `src\sources.txt` and generate Julia source file with one modula per glass catalog and one `const Glass` definition per glass in that catalog. You should call this function before you use `AGFFileReader` otherwise your glass catalog will be empty"""
function initialize_AGFFileReader()
    #not as efficient as it could be since it reads the AGF glass data then writes Julia source files and includes them. Legacy code that was complicated to turn into Expr type statements instead of text files.
    glass_defs = joinpath(scratch_directory(), "jl/AGFGlassCat.jl")

    if !isfile(glass_defs)
        download_AGF_files()
    end
    if isfile(glass_defs)
        AGFFileReader.include(glass_defs) #This should eval the included files in the AGFFileReader module
    else
        @warn "No glass files found. This could be because you did not have internet access to access the glass files."
    end
end
export initialize_AGFFileReader

include("constants.jl")

include("GlassTypes.jl")
export info, glassname, Glass, AbstractGlass
include("BaseGlasses.jl")
include("Air.jl")
export Air, isair

include("GlassDownload.jl")

#if the glass catalogs have been downloaded include them. Required because can't ship glass catalogs with the code and Registrator doesn't allow build process to modify source. When building on Julia Registrator server AGFGLASSCAT_PATH won't exist so this file won't be included.

include("OTHER.jl")
# include functionality for managing runtime (dynamic) glass cats: MIL_GLASSES and MODEL_GLASSES
include("runtime.jl")
export glassfromMIL, modelglass

# include functions for searching the glass cats
include("search.jl")
export glass_catalogs, glass_names, find_glass

include("utilities.jl")
export plot_indices, index, absairindex, absorption, draw_glass_map

# include utility functions for maintaining the AGF source list
include("sources.jl")
export add_agf

#extension functions for graphing
"""
    plot_indices(glass::AbstractGlass; polyfit=false, fiterror=false, degree=5, temperature=20°C, pressure=1Atm, nsamples=300, sampling_domain="wavelength")

Plot the refractive index for `glass` for `nsamples` within its valid range of wavelengths, optionally at `temperature` and `pressure`.
`polyfit` will show a polynomial of optionally specified `degree` fitted to the data, `fiterror` will also show the fitting error of the result.
`sampling_domain` specifies whether the samples will be spaced uniformly in "wavelength" or "wavenumber".
"""
function plot_indices end
export plot_indices


"""
    draw_glass_map(glasscatalog::Module; λ::Length = 550nm, glassfontsize::Integer = 3, showprefixglasses::Bool = false)

Draw a scatter plot of index vs dispersion (the derivative of index with respect to wavelength). Both index and
dispersion are computed at wavelength λ.

Choose glasses to graph using the glassfilterprediate argument. This is a function that receives a Glass object and returns true if the glass should be graphed.

If showprefixglasses is true then glasses with names like `F_BAK7` will be displayed. Otherwise glasses that have a
leading letter prefix followed by an underscore, such as `F_`, will not be displayed.

The index formulas for some glasses may give incorrect results if λ is outside the valid range for that glass. This can
give anomalous results, such as indices less than zero or greater than 6. To filter out these glasses set maximumindex
to a reasonable value such as 3.0.

example: plot only glasses that do not contain the strings "E_" and "J_"

draw_glass_map(NIKON,showprefixglasses = true,glassfilterpredicate = (x) -> !occursin("J_",string(x)) && !occursin("E_",string(x)))
"""
function draw_glass_map end
export draw_glass_map

end # module


