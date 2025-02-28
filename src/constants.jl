# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

using Unitful

const TEMP_REF = 20.0
const PRESSURE_REF = 1.0
const TEMP_REF_UNITFUL = TEMP_REF * u"°C"
export TEMP_REF, PRESSURE_REF

const DISPFORM_NAMES = ["Schott", "Sellmeier1", "Herzberger", "Sellmeier2", "Conrady", "Sellmeier3", "HandbookOfOptics1", "HandbookOfOptics2", "Sellmeier4", "Extended1", "Sellmeier5", "Extended2", "Extended3"]
const STATUS = ["Standard", "Preferred", "Obsolete", "Special", "Melt"]





# NOTE: if you change JL_DIR or AGFGLASSCAT_PATH, you also need to change the include statement in AGFFileReader.jl
