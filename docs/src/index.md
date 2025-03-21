```@meta
CurrentModule = AGFFileReader
```

# AGFFileReader
AGFFileReader is a library for reading AGF files. The contents of an AGF file can vary but usually each file contains material property information for several optical materials made by a single manufacturer. By convention the name of the AGF file is assumed to be the manufacturer name. For example SCHOTT.AGF contains material data for glasses made by the Schott company. AGF files are available from many publicly accessible websites. 

AGFFileReader automates the process of downloading and installing an extensive library of AGF files from many sources. After you install the package you must call `initialize_AGFFileReader()`. If no glass files have been downloaded this will download files from the list in sources.txt in the src directory. If glass files have been downloaded this will include them in the AGFFileReader module. Each AGF file gets its own module, whose name will match that of the AGF file. Each material in that AFG file is assigned a corresponding `Glass` type. 

Glass types are accessed like so: `AGFFileReader.CATALOG_NAME.GLASS_NAME`, e.g.

```julia
AGFFileReader.SUMITA.LAK7
AGFFileReader.SCHOTT.PK3
```

All glasses and catalogs are exported in their respective modules:

```julia
julia> using AGFFileReader

julia> NIKON.PK2
Glass

julia> using AGFFileReader.NIKON

julia> PK2
```
To see all loaded glass catalogs:
```julia
julia> glass_catalogs()
14-element Vector{Any}:
 AGFFileReader.ARTON
 AGFFileReader.BIREFRINGENT
 ...
 AGFFileReader.UMICORE
 AGFFileReader.ZEON
 ```

 To see all glasses in a catalog:
 ```julia
 julia> glass_names(HIKARI)
331-element Vector{Any}:
 :BAF10
 :BAF11
 ...
 :SSK2
 :SSK8
 ```

 To get all glasses currently loaded in all catalogs:
 ```julia
 julia> glass_names()
14-element Vector{Pair{Module, Vector{Any}}}:
        AGFFileReader.ARTON => [:D4531F, :D4532, :D4540, :DX4900, :F4520, :F5023]
 AGFFileReader.BIREFRINGENT => [:ADP, :ADP_E, :AGASS3, :AGASS3_E, :AGGAS2, :AGGAS2_E, :AGGASE2, :AGGASE2_E, :AL2O3, :AL2O3_E  …  :TE, :TEO2, :TEO2_E, :TE_E, :YVO4, :YVO4_E, :ZNGEP2, :ZNGEP2_E, :ZNO, :ZNO_E]
    ...
      AGFFileReader.UMICORE => [:GASIR1, :GASIR2]
         AGFFileReader.ZEON => [:E48R, :_330R, :_480R]
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

```@docs
AGFFileReader.info
```
Example:
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

You can plot indices using the [`AGFFileReader.plot_indices`](@ref) function

Example:

```
julia> plot_indices(SCHOTT.FK3)
```

![Refractive Index vs. wavelength for SCHOTT.FK3](assets/SCHOTT.FK3-indexplot.png)

You can draw glass maps using the [`AGFFileReader.draw_glass_map`](@ref) function and filter the results in sophisticated ways.

Example:

```julia
julia> draw_glass_map(HIKARI)
```

![Glass map for the HIKARI glass catalog](assets/glassmapHIKARI.png)

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

