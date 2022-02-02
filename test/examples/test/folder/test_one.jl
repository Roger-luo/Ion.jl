using Test

@testset "test folder/one" begin
    @test true
    @test true
    @test false
end

# @testset "test folder/err" begin
#     error("this is an error")
# end