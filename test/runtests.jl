using Test


using Promises

@testset "Public API" begin
    @test 1 == @await Promise((res,rej) -> res(1))
    
    @test Promises.await_settled(Promises.resolve(1)) === Promises.Resolved{Int64}(1)
    @test Promises.Resolved <: Promises.PromiseSettledResult
    @test Promises.await_settled(Promises.reject(1)) == Promises.Rejected(1)
    
    @test [1] == @await Promises.all([
        Promises.any([
            Promises.race([
                Promises.resolve(1)
            ])
        ])
    ])
end

