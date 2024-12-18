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
function plot_indices end
function drawglassmap end
end # module


