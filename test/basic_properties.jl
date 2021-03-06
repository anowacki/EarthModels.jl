using Test
using EarthModels

@testset "Basic properties" begin
    let m = SteppedLayeredModel(1, 2, [0.5, 1], [1, 2], [3, 4], [5, 6], false,
            [], [], [], [], [], true, [10, 20], [100, 200])
        @test !isanisotropic(m)
        @test surface_radius(m) == 1.0
        @test radius(m, 0.25) == 0.75
        @test depth(m, 0.25) == 0.75
        @test hasattenuation(m)
    end
    let a = 1, n = 2, arr = rand(2), m = SteppedLayeredModel(a, n, [0.005 + 0.99rand(), 1],
            arr, arr, arr, true, arr, arr, arr, arr, arr, false, [], [])
        @test isanisotropic(m)
        @test !hasattenuation(m)
    end
end