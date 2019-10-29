"""
# EarthModels

Give various physical properties of the interior of the Earth for a range of
models.

### Physical properties

All models should have:

- P-wave velocity (accessed with the `vp` function) in km/s
- S-wave velocity (`vs`) in km/s
- Density (`density`) in g/cm^3
- (Average) Earth surface radius (`surface_radius`) in km

Models may also provide:

- VPV, VPH, VSV and VSH for radially-anistropic models (`vpv`, etc.) in km/s
- Radial anisotropy parameter η (`eta`)
- Shear wave quality factor (`Qμ`)
- Bulk sound quality factor (`Qκ`)

Derived properties can be computed for all models:

- Mass up to radius r (`mass`) in kg
- Mass from radius r to the surface (`surface_mass`) in kg
- Pressure (`pressure`) in Pa
- Acceleration due to gravity g (`gravity`) in m/s^2
- Bulk and shear module (`bulk_modulus`, `shear_modulus`) in GPa
- Radius from centre of Earth to a given depth (`depth`) in km

### Currently implemented models

- PREM
- AK135
"""
module EarthModels

__init__() = @warn("""
    EarthModels.jl is deprecated and replaced by SeisModels.jl (https://github.com/anowacki/SeisModels.jl).

    SeisModels.jl contains the same functionality as EarthModels and more.
    EarthModels will no longer be updated.
    """)

import QuadGK: quadgk

export
    # Model types
    EarthModel,
    EarthModel1D,
    LinearLayeredModel,
    PREMPolyModel,
    SteppedLayeredModel,

    # Model properties
    depth,
    hasattenuation,
    isanisotropic,
    radius,
    surface_radius,

    # Evaluation functions
    evaluate,
    vp,
    vs,
    density,
    vph,
    vpv,
    vsh,
    vsv,
    eta,
    Qμ, Qmu,
    Qκ, Qkappa,

    # Derived properties
    bulk_modulus,
    gravity,
    mass,
    moment_of_inertia,
    poissons_ratio,
    pressure,
    shear_modulus,
    surface_mass,
    youngs_modulus,

    # Models
    AK135,
    PREM,

    # IO
    read_mineos,
    write_mineos

"""
Abstract supertype of all models of the Earth in the `EarthModels` module.
All models should be a subtype of this or one of `EarthModel`'s abstract
subtypes.
"""
abstract type EarthModel end

# Allow models to be broadcasted as scalars
Base.broadcastable(x::EarthModel) = Ref(x)

## Basic properties of models
include("basic_properties.jl")

## 1D models
include("earth_models_1d.jl")
# Predefined 1D models
include("prem.jl")
include("ak135.jl")

## IO
include("io.jl")

## Deprecated functions
rho(m::EarthModel, args...; kwargs...) =
    (@warn("`rho` is deprecated; use `density` instead"); density(m, args...; kwargs...))
export rho

end # module
