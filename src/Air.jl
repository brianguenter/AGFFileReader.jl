# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

struct AirType <: AbstractGlass end
Base.show(io::IO, ::AirType) = print(io, "Air")
glassname(::AirType) = "AGFFileReader.Air"

"""
    isair(a) -> Bool

Tests if a is Air.
"""
isair(::AirType) = true
isair(::AbstractGlass) = false

function info(io::IO, ::AirType)
    println(io, "AGFFileReader.Air")
    println(io, "Material representing air, RI is always 1.0 at system temperature and pressure, absorption is always 0.0.")
end

"""
Special glass to represent air. Refractive index is defined to always be 1.0 for any temperature and pressure (other indices are relative to this).
"""
const Air = AirType()
