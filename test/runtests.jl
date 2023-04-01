using Exams
using Test

@testset "example" begin 
    include("example.jl") 
    generate_exam(1)
    @test isfile("exam_spanish_1.tex")
    @test isfile("exam_spanish_1.pdf")
    rm("exam_spanish_1.pdf",force=true)
    rm("exam_spanish_1.tex",force=true)
    rm("exam_results.csv",force=true)
    rm("exam.bson",force=true)
end
