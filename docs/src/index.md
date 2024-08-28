```@meta
CurrentModule = AGFFileReader
```

# AGFFileReader
Documentation for [AGFFileReader](https://github.com/rambunctiousapple/AGFFileReader.jl).

AGFFileReader is a library for reading AGF files, a file format widely used in optical design. The contents of an AGF file can vary but usually each file contains material property information for several optical materials made by a single manufacturer. By convention the name of the AGF file is assumed to be the manufacturer name. For example SCHOTT.AGF contains material data for glasses made by the Schott company. AGF files are available from many publicly accessible websites. 

AGFFileReader automates the process of downloading and installing an extensive library of AGF files from many sources. When the AGFFileReader package is first installed the build process will attempt to download AGF glass files from the sources in the file `data/sources.txt`. 

AGFFileReader transforms the information in the AGF files into Julia files stored in the `data` subdirectory, which is created automatically during the build process. Each AGF file gets its own module, whose name will match that of the AGF file. Each material is assigned a corresponding Julia type. 
 
 ## Using installed glasses

Glass types are accessed like so: `AGFFileReader.CATALOG_NAME.GLASS_NAME`, e.g.

```julia
AGFFileReader.SUMITA.LAK7
AGFFileReader.SCHOTT.PK3
```

All glasses and catalogs are exported in their respective modules, so it is possible to invoke `using` calls for convenience, e.g.

```julia
using AGFFileReader
SCHOTT.PK3
using AGFFileReader.SCHOTT
N_BK7
```



At the Julia REPL you can use tab to autocomplete glass names or double tab to show glass types available in a particular glass library. For example, this is the result of typing tab twice after typing the intitial string `SCHOTT.N_LA`:

```
julia> SCHOTT.N_LA
N_LAF2     N_LAF33     N_LAF7      N_LAK21     N_LAK33B    N_LAK9      N_LASF41    N_LASF45HT  N_LASF55
N_LAF21    N_LAF34     N_LAK10     N_LAK22     N_LAK34     N_LASF31    N_LASF43    N_LASF46    N_LASF9
N_LAF3     N_LAF35     N_LAK12     N_LAK28     N_LAK7      N_LASF31A   N_LASF44    N_LASF46A   N_LASF9HT
N_LAF32    N_LAF36     N_LAK14     N_LAK33A    N_LAK8      N_LASF40    N_LASF45    N_LASF46B
```

If you use the VSCode IDE its Intellisense autocompletion provides similar functionality.

All catalog glasses are of type [`AGFFileReader.Glass`](@ref).
Note that special characters in glass/catalog names are replaced with `_`.
There is a special type and constant value for air: [`AGFFileReader.Air`](@ref).

[Unitful.jl](https://github.com/PainterQubits/Unitful.jl) is used to manage units, meaning any valid unit can be used for all arguments, e.g., wavelength can be passed in as μm or nm (or cm, mm, m, etc.).
Non-unitful options are also available, in which case units are assumed to be μm, °C and Atm for length, temperature and pressure respectively.

`TEMP_REF` and `PRESSURE_REF` are constants:

```julia
const TEMP_REF = 20.0 # °C
const PRESSURE_REF = 1.0 # Atm
```

## Utility functions

You can print out glass properties with the `info` function:

```
julia> info(SCHOTT.FK3)
ID:                                                AGF:905
Dispersion formula:                                Sellmeier1 (2)
Dispersion formula coefficients:
     K₁:                                           0.973346627
     L₁:                                           0.00640795469
     K₂:                                           0.146642231
     L₂:                                           0.020565293
     K₃:                                           0.679304225
     L₃:                                           80.4965389
Valid wavelengths:                                 0.3μm to 2.5μm
Reference temperature:                             20.0°C
Thermal ΔRI coefficients:
     D₀:                                           -4.9e-6
     D₁:                                           1.23e-8
     D₂:                                           -1.19e-10
     E₀:                                           3.45e-7
     E₁:                                           7.72e-10
     λₜₖ:                                          0.18
TCE (÷1e-6):                                       8.2
Ignore thermal expansion:                          false
Density (p):                                       2.27g/m³
ΔPgF:                                              -0.0003
RI at sodium D-Line (587nm):                       1.4645
Abbe Number:                                       65.77
Cost relative to N_BK7:                            ?
Environmental resistance:
     Climate (CR):                                 2.0
     Stain (FR):                                   3.0
     Acid (SR):                                    52.4
     Alkaline (AR):                                2.0
     Phosphate (PR):                               1.0
Status:                                            Special (3)
Melt frequency:                                    0
Exclude substitution:                              false
Transmission data:
     Wavelength   Transmission      Thickness
          0.3μm           0.05         25.0mm
         0.31μm           0.19         25.0mm
         0.32μm           0.41         25.0mm
        0.334μm           0.74         25.0mm
         0.35μm           0.89         25.0mm
        0.365μm          0.964         25.0mm
         0.37μm          0.971         25.0mm
         0.38μm           0.98         25.0mm
         0.39μm          0.984         25.0mm
          0.4μm          0.985         25.0mm
        0.405μm          0.986         25.0mm
         0.42μm          0.987         25.0mm
        0.436μm          0.989         25.0mm
         0.46μm           0.99         25.0mm
          0.5μm          0.993         25.0mm
        0.546μm          0.993         25.0mm
         0.58μm          0.993         25.0mm
         0.62μm          0.993         25.0mm
         0.66μm          0.993         25.0mm
          0.7μm          0.993         25.0mm
         1.06μm          0.995         25.0mm
         1.53μm           0.97         25.0mm
         1.97μm           0.93         25.0mm
        2.325μm           0.59         25.0mm
          2.5μm           0.34         25.0mm
```
You can also plot glass properties with the `plot_indices` function

```
julia> plot_indices(SCHOTT.FK3)
```

![Refractive Index vs. wavelength for SCHOTT.FK3](assets/SCHOTT.FK3-indexplot.png)

## How AGFFileReader works

The central configuration file for AGFFileReader is located at `src/AGFFileReader/data/sources.txt`. Each line in the file corresponds to one AGF source, which is described by 2 to 4 space-delimited columns. The first column provides the installed module name for the catalog, e.g. `AGFFileReader.NIKON`. The second column is the expected SHA256 checksum for
the AGF file.

The final two columns are optional, specifying download instructions for acquiring the zipped AGF files
automatically from the web. The fourth column allows us to use POST requests to acquire files from interactive sites.

## Adding glass catalogs
`sources.txt` can be edited freely to add more glass catalogs. However, this is a somewhat tedious process, so we have a
convenience function for adding a locally downloaded AGF file to the source list.

```@docs
AGFFileReader.add_agf
```

