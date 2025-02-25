# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

module AGFFileReader

using Polynomials
using Unitful
using StaticArrays
using Base: @.
import Unitful: Length, Temperature, Quantity, Units
using Unitful.DefaultSymbols





include("constants.jl")

include("GlassTypes.jl")
export info, glassname, Glass, AbstractGlass
include("BaseGlasses.jl")
include("Air.jl")
export Air, isair

# include built glass cat source files
@assert AGFGLASSCAT_PATH === joinpath(@__DIR__, "data", "jl", "AGFGlassCat.jl")

#need to fix this so it runs build process if agf data is not already downloaded
# if !isfile(AGFGLASSCAT_PATH)
#     @warn "$(basename(AGFGLASSCAT_PATH)) not found! Running build steps."
#     Pkg.build("AGFFileReader"; verbose=true)
# end

include("data/jl/AGFGlassCat.jl") # this needs to be literal for intellisense to work
include("OTHER.jl")
# include functionality for managing runtime (dynamic) glass cats: MIL_GLASSES and MODEL_GLASSES
include("runtime.jl")
export glassfromMIL, modelglass

# include functions for searching the glass cats
include("search.jl")
export glasscatalogs, glassnames, findglass

include("utilities.jl")
export plot_indices, index, polyfit_indices, absairindex, absorption, drawglassmap

# include utility functions for maintaining the AGF source list
include("sources.jl")
export add_agf

# include build utility scripts to make testing them a bit easier
include("generate.jl")

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
    drawglassmap(glasscatalog::Module; λ::Length = 550nm, glassfontsize::Integer = 3, showprefixglasses::Bool = false)

Draw a scatter plot of index vs dispersion (the derivative of index with respect to wavelength). Both index and
dispersion are computed at wavelength λ.

Choose glasses to graph using the glassfilterprediate argument. This is a function that receives a Glass object and returns true if the glass should be graphed.

If showprefixglasses is true then glasses with names like `F_BAK7` will be displayed. Otherwise glasses that have a
leading letter prefix followed by an underscore, such as `F_`, will not be displayed.

The index formulas for some glasses may give incorrect results if λ is outside the valid range for that glass. This can
give anomalous results, such as indices less than zero or greater than 6. To filter out these glasses set maximumindex
to a reasonable value such as 3.0.

example: plot only glasses that do not contain the strings "E_" and "J_"

drawglassmap(NIKON,showprefixglasses = true,glassfilterpredicate = (x) -> !occursin("J_",string(x)) && !occursin("E_",string(x)))
"""
function drawglassmap end
export drawglassmap

end # module


