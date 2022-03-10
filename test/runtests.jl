using Test

using Promises

# (most tests are inside src/notebook.jl, not here)
@testset "Public API" begin
    @test 1 == @await Promise((res,rej) -> res(1))
    @test 123 == @await @async_promise begin
        sleep(.2)
        123
    end
    f1 = @async_promise x -> begin
        sleep(x)
        123
    end
    f2 = @async_promise function(x)
        sleep(x)
        123
    end
    f3 = @async_promise function f3f(x)
        sleep(x)
        123
    end
    f4 = @async_promise function f4f(x)::Integer
        sleep(x)
        123
    end
    
    for f in [f1,f2,f3,f4]
        p = f1(.2)
        @test p isa Promise
        @test 123 == @await p
    end
    
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

