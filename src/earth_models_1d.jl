#==============
1D Earth models
==============#
"""
Abstract type for radially-symmetric models of the Earth.  1D Earth models should
be subtypes of this.
"""
abstract type EarthModel1D <: EarthModel end

const model_variables_EarthModel1D = (:vp, :vs, :density, :vph, :vpv, :vsh, :vsv,
    :eta, :Qμ, :Qκ)
const model_names_EarthModel1D = ("isotropic average Vp", "isotropic average Vs",
    "density", "Vph", "Vpv", "Vsh", "Vsv", "η", "Qμ", "Qκ")
const model_units_EarthModel1D = (" (km/s)", " (km/s)", " (g/cm^3)", " (km/s)",
    " (km/s)", " (km/s)", " (km/s)", "", "", "")

"""
    findlayer(m::EarthModel1D, r) -> layer_index

Return the layer index in which radius `r` km is located in the EarthModel1D `m`.
"""
function findlayer(m::EarthModel1D, r::Real)
    r < 0. && throw(DomainError(r, "radius cannot be negative"))
    r > m.a && throw(DomainError(r, "radius is greater than Earth radius for model ($(m.a) km)"))
    for i in 1:length(m.r)
        r < m.r[i] && return i
    end
    length(m.r)
end


"""
    PREMPolyModel <: EarthModel1D

Type describing the Earth as a set of layers within which properties vary
according to a set of polynomials.

Physical parameters are represented by arrays of size `(order+1, n)`, where `n`
is the number of layers, and `order` is the order of polynomial which is
used to represent the parameter.  Hence a constant layer has size `(1,n)`,
and to compute the value of `x` in layer `i`, for an Earth radius of `a` km,
at a radius of `r` km, the expression is:

    val_x = x[i,1] + (r/a)*x[i,2] + (r/a)^2*x[i,3] ... (r/a)^order*x[i,order+1]
"""
struct PREMPolyModel <: EarthModel1D
    "Earth radius in km"
    a :: Float64
    "Number of distinct layers"
    n :: Int
    "Radii in km of top of each layer"
    r :: Vector{Float64}
    "Physical parameters"
    vp :: Array{Float64}
    vs :: Array{Float64}
    density :: Array{Float64}
    "Optional anisotropic parameters"
    aniso :: Bool
    vph :: Array{Float64}
    vpv :: Array{Float64}
    vsh :: Array{Float64}
    vsv :: Array{Float64}
    eta :: Array{Float64}
    "Optional attenuation parameters"
    attenuation :: Bool
    Qμ :: Array{Float64}
    Qκ :: Array{Float64}
end

# Evaluation routines--all documented here
# TODO: Use Horner's method à la Base.@evalpoly
for (sym, name, unit) in zip(model_variables_EarthModel1D, model_names_EarthModel1D, model_units_EarthModel1D)
    @eval begin
        """
            $(split(string($sym), ".")[end])(m::EarthModel1D, r; depth=false) -> $($name)
        
        Return the value of $($name)$($unit) for model `m` at radius `r` km.
        
        If `depth` is `true`, then `r` is given as a depth in km instead.
        """
        function ($sym)(m::PREMPolyModel, r::Real; depth::Bool=false)
            length(m.$sym) > 0 || throw(ArgumentError("$($name) not defined for model"))
            depth && (r = radius(m, r))
            ir = findlayer(m, r)
            x = r/m.a
            val = m.$(sym)[1,ir]
            for k in 2:size(m.$sym, 1)
                val = val + m.$(sym)[k,ir]*x^(k-1)
            end
            val
        end
    end
end
# Alternative names
const ρ = density
const Qmu = Qμ
const Qkappa = Qκ

"""
    evaluate(m::EarthModel1D, field::Symbol, r) -> vals

Evaluate the model `m` at radius `r` km for the different property/ies in `field`,
returning a scalar for scalar input, and an array for array input.
"""
function evaluate(m::PREMPolyModel, field::Symbol, r; depth::Bool=false)
    y = getfield(m, field)
    length(y) > 0 || throw(ArgumentError("'$field' not defined for model"))
    depth && (r = radius(m, r))
    ir = findlayer(m, r)
    x = r/m.a
    val = y[1,ir]
    for k in 2:size(y, 1)
        val = val + y[k,ir]*x^(k-1)
    end
    val
end



"""
    SteppedLayeredModel <: EarthModel1D

A `SteppedLayeredModel` contains `n` layers with maximum radius `r` km,
each with a constant velocity.
"""
struct SteppedLayeredModel <: EarthModel1D
    "Earth radius in km"
    a :: Float64
    "Number of layers"
    n :: Int
    "Radii in km of top of each layer"
    r :: Vector{Float64}
    "Physical parameters"
    vp :: Vector{Float64}
    vs :: Vector{Float64}
    density :: Vector{Float64}
    "Optional anisotropic parameters"
    aniso :: Bool
    vph :: Vector{Float64}
    vpv :: Vector{Float64}
    vsh :: Vector{Float64}
    vsv :: Vector{Float64}
    eta :: Vector{Float64}
    "Optional attenuation parameters"
    attenuation :: Bool
    Qμ :: Vector{Float64}
    Qκ :: Vector{Float64}
end

for sym in model_variables_EarthModel1D
    @eval function ($sym)(m::SteppedLayeredModel, r::Real; depth::Bool=false)
        length(m.$sym) > 0 ||
            throw(ArgumentError("'$split(string($sym), ".")[end]' not defined for model"))
        depth && (r = radius(m, r))
        m.$(sym)[findlayer(m, r)]
    end
end

function evaluate(m::SteppedLayeredModel, field::Symbol, r; depth::Bool=false)
    length(getfield(m, field)) > 0 ||
        throw(ArgumentError("$field' not defined for model"))
    depth && (r = radius(m, r))
    getfield(m, field)[findlayer(m, r)]
end


"""
    LinearLayeredModel <: EarthModel1D

A `LinearLayeredModel` contains `n` points at which velocities are defined, with
linear interpolation between them.  Hence there are `n - 1` layers.

Discontinuities are represented by two layers with the same radii.
"""
struct LinearLayeredModel <: EarthModel1D
    "Earth radius in km"
    a :: Float64
    "Number of layers"
    n :: Int
    "Radii in km of top of each layer"
    r :: Vector{Float64}
    "Physical parameters"
    vp :: Vector{Float64}
    vs :: Vector{Float64}
    density :: Vector{Float64}
    "Optional anisotropic parameters"
    aniso :: Bool
    vph :: Vector{Float64}
    vpv :: Vector{Float64}
    vsh :: Vector{Float64}
    vsv :: Vector{Float64}
    eta :: Vector{Float64}
    "Optional attenuation parameters"
    attenuation :: Bool
    Qμ :: Vector{Float64}
    Qκ :: Vector{Float64}
end

function findlayer(m::LinearLayeredModel, r::Real)
    r < 0. && error("Radius cannot be negative")
    r > m.a && error("Radius $r km is greater than Earth radius for model ($(m.a) km)")
    for i in 1:(length(m.r) - 1)
        r < m.r[i+1] && return i
    end
    return length(m.r) - 1
end

for sym in model_variables_EarthModel1D
    @eval function ($sym)(m::LinearLayeredModel, r::Real; depth::Bool=false)
        length(m.$sym) > 0 ||
            throw(ArgumentError("'$(split(string($sym), ".")[end])' not defined for model"))
        depth && (r = radius(m, r))
        ir = findlayer(m, r)
        r0 = m.r[ir]
        r1 = m.r[ir+1]
        (m.$sym[ir]*(r1 - r) + m.$sym[ir+1]*(r - r0))/(r1 - r0)
    end
end

function evaluate(m::LinearLayeredModel, field::Symbol, r; depth::Bool=false)
    y = getfield(m, field)
    length(y) > 0 ||
        throw(ArgumentError("'$field' not defined for model"))
    depth && (r = radius(m, r))
    ir = findlayer(m, r)
    r0 = m.r[ir]
    r1 = m.r[ir+1]
    (y[ir]*(r1 - r) + y[ir+1]*(r - r0))/(r1 - r0)
end



## Derived quantities
"""
    bulk_modulus(m::EarthModel1D, r) -> K

Return the bulk modulus `K` in GPa at radius `r` in the model `m`.
"""
bulk_modulus(m::EarthModel1D, r) = density(m, r)*vp(m, r)^2 - 4/3*shear_modulus(m, r)

const NewtonG = 6.67428e-11
"""
    gravity(m::EarthModel1D, r) -> g

Return the acceleration due to gravity, `g`, in m/s^2 at radius `r` km.
"""
gravity(m::EarthModel1D, r) = (r == 0) ? 0. : NewtonG*mass(m, r)/(r*1.e3)^2

"""
    mass(m::EarthModel1D, r) -> mass

Return the mass in kg between the centre of the model and the radius `r` km.
"""
function mass(m::PREMPolyModel, r)
	l = findlayer(m, r)
	r *= 1.e3 # SI
	M = 0.
	for i = 1:l
		if i == 1
			R0 = 0.
		else
			R0 = m.r[i-1]*1.e3
		end
		if i < l
			R = m.r[i]*1.e3
		else
			R = r
		end
        for k in 1:size(m.density, 1)
            rho = m.density[k,i]/m.a^(k-1)*1.e3^(2-k)/(k+2)
            M += rho*(R^(k+2) - R0^(k+2))
        end
	end
	4*π*M
end

function mass(m::SteppedLayeredModel, r)
    l = findlayer(m, r)
    r *= 1.e3
    M = 0.
    for i in 1:l
        R0 = i == 1 ? 0. : m.r[i-1]*1.e3
        R = i < l ? m.r[i]*1.e3 : r
        M += m.density[i]*(R^3 - R0^3)
    end
    4/3*π*M
end

function mass(m::LinearLayeredModel, r)
    l = findlayer(m, r)
    r *= 1.e3
    M = 0.
    for i in 1:l
        m.r[i] == m.r[i+1] && continue
        R0 = m.r[i]*1.e3
        R = i == l ? r : m.r[i+1]*1.e3
        dρ_dr = 1.e3*(m.density[i+1] - m.density[i])/(m.r[i+1]*1.e3 - R0)
        ρ0 = 1.e3*m.density[i] - dρ_dr*R0
        M += ρ0*(R^3 - R0^3)/3 + dρ_dr*(R^4 - R0^4)/4
    end
    4*π*M
end

"""
    pressure(m::EarthModel1D, r) -> p

Return the pressure `p` in Pa at radius `r` km.
"""
function pressure(m::EarthModel1D, r)
    f(r) = pressure_integration_func(m, r)
    1.e3*quadgk(f, r, m.a)[1]
end
pressure_integration_func(m::EarthModel1D, r) = 1.e3*density(m, r)*gravity(m, r)

"""
    poissons_ratio(m, r) -> ν

Return the Poisson's ratio for the model `m` given a radius `r` in km.
The calculation uses the isotropic average velocities at `r`.
"""
function poissons_ratio(m::EarthModel1D, r)
    G = shear_modulus(m, r)
    K = bulk_modulus(m, r)
    (3K - 2G)/(6K + 2G)
end

"""
    shear_modulus(m::EarthModel1D, r) -> μ

Return the shear modulus `μ` (often also called G) in GPa at radius `r` in the
model `m`.
"""
shear_modulus(m::EarthModel1D, r) = vs(m, r)^2*density(m, r)

"""
    surface_mass(m::EarthModel1D, r) -> mass

Return the mass in kg betwen radius `r` km and the surface.
"""
surface_mass(m::EarthModel1D, r) = mass(m, m.a) - mass(m, r)

"""
    youngs_modulus(m, r) -> E

Return the Young's modulus `E` in GPa for the model `m` given a radius `r` in km.
"""
youngs_modulus(m::EarthModel1D, r) = 2*shear_modulus(m, r)*(1 + poissons_ratio(m, r))


"""
    moment_of_inertia(m, r0=0, r1=surface_radius(m)) -> I

Return the moment of interia `I` in kg m² for the model `m` between radii `r0`
and `r1` in km.
"""
moment_of_inertia(m::EarthModel1D, r0=0, r1=surface_radius(m)) =
    8/3*π*quadgk(r->1e3*density(m, r/1e3)*r^4, r0*1e3, r1*1e3)[1]
