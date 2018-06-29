# This file provides getter-type methods which essentially define the fields
# needed in any concrete subtype of EarthModel.

"""
    depth(m, radius) -> depth

Return the `depth` in km for the model `m` given a `radius` in km.
"""
depth(m::EarthModel, radius) = surface_radius(m) - radius

"""
    radius(m, depth) -> radius

Return the `radius` in km for the model `m` given a `depth` in km.
"""
radius(m::EarthModel, depth) = surface_radius(m) - depth

"""
    surface_radius(m) -> radius

Return the surface radius in km of the `EarthModel` `m`.
"""
surface_radius(m::EarthModel) = m.a