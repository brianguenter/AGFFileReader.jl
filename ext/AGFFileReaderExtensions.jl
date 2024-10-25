module AGFFileReaderExtensions
using AGFFileReader
using GR
using Plots
import ForwardDiff

#NOTE: for some reason drawglassmap doesn't work correctly, get error saying ForwardDiff is not defined. Not sure where this error is coming from.

"""
    plot_indices(glass::AbstractGlass; polyfit=false, fiterror=false, degree=5, temperature=20°C, pressure=1Atm, nsamples=300, sampling_domain="wavelength")

Plot the refractive index for `glass` for `nsamples` within its valid range of wavelengths, optionally at `temperature` and `pressure`.
`polyfit` will show a polynomial of optionally specified `degree` fitted to the data, `fiterror` will also show the fitting error of the result.
`sampling_domain` specifies whether the samples will be spaced uniformly in "wavelength" or "wavenumber".
"""
function plot_indices(glass::AbstractGlass; polyfit::Bool=false, fiterror::Bool=false, degree::Int=5, temperature::Temperature=TEMP_REF_UNITFUL, pressure::Float64=PRESSURE_REF, nsamples::Int=300, sampling_domain::String="wavelength")
    if isair(glass)
        wavemin = 380 * u"nm"
        wavemax = 740 * u"nm"
    else
        wavemin = glass.λmin * u"μm"
        wavemax = glass.λmax * u"μm"
    end

    if (sampling_domain == "wavelength")
        waves = range(wavemin, stop=wavemax, length=nsamples)      # wavelength in um
    elseif (sampling_domain == "wavenumber")
        sigma_min = 1.0 / wavemax
        sigma_max = 1.0 / wavemin
        wavenumbers = range(sigma_min, stop=sigma_max, length=nsamples) # wavenumber in um.^-1
        waves = 1.0 ./ wavenumbers
    else
        error("Invalid sampling domain, should be \"wavelength\" or \"wavenumber\"")
    end

    p = plot(xlabel="wavelength (um)", ylabel="refractive index")

    f = w -> begin
        try
            return index(glass, w, temperature=temperature, pressure=pressure)
        catch
            return NaN
        end
    end
    indices = [f(w) for w in waves]
    plot!(ustrip.(waves), indices, color=:blue, label="From Data")

    if polyfit
        (p_indices, _) = polyfit_indices(waves, indices, degree=degree)
        plot!(ustrip.(waves), p_indices, color=:black, markersize=4, label="Polyfit")
    end

    if polyfit && fiterror
        err = p_indices - indices
        p2 = plot(xlabel="wavelength (um)", ylabel="fit error")
        plot!(ustrip.(waves), err, color=:red, label="Fit Error")
        p = plot(p, p2, layout=2)
    end

    plot!(title="$(glassname(glass)) dispersion")
end


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
function drawglassmap(glasscatalog::Module; λ::Length=550nm, glassfontsize::Integer=3, showprefixglasses::Bool=false, minindex=1.0, maxindex=3.0, mindispersion=-0.3, maxdispersion=0.0, glassfilterpredicate=(x) -> true)
    wavelength = Float64(ustrip(uconvert(μm, λ)))
    indices = Vector{Float64}(undef, 0)
    dispersions = Vector{Float64}(undef, 0)
    glassnames = Vector{String}(undef, 0)

    for name in names(glasscatalog)
        glass = eval(:($glasscatalog.$name))
        glassstring = String(name)
        hasprefix = occursin("_", glassstring)

        if typeof(glass) !== Module && (minindex <= index(glass, wavelength) <= maxindex)
            f(x) = index(glass, x)
            g = x -> ForwardDiff.derivative(f, x)
            dispersion = g(wavelength)

            # don't show glasses that have an _ in the name. This prevents cluttering the map with many glasses of
            # similar (index, dispersion).
            if glassfilterpredicate(glass) && (mindispersion <= dispersion <= maxdispersion) && (showprefixglasses || !hasprefix)
                push!(indices, index(glass, wavelength))
                push!(dispersions, dispersion)
                push!(glassnames, String(name))
            end
        end
    end

    font = Plots.font(family="Sans", pointsize=glassfontsize, color=RGB(0.0, 0.0, 0.4))
    series_annotations = Plots.series_annotations(glassnames, font)
    scatter(
        dispersions,
        indices;
        series_annotations,
        markeralpha=0.0,
        legends=:none,
        xaxis="dispersion @$λ",
        yaxis="index",
        title="Glass Catalog: $glasscatalog",
        xflip=true) #should use markershape = :none to prevent markers from being drawn but this option doesn't work. Used markeralpha = 0 so the markers are invisible. A hack which works.
end

end #module
