using Exams
using Test

@testset "example" begin 
    include("example.jl") 
    generate_exam(1)
    @test isfile("exam_spanish_1.pdf")
    rm("exam_spanish_1.pdf",force=true)
    rm("exam_spanish_1.tex",force=true)
    rm("exam_spanish_1.aux",force=true)
    rm("exam_spanish_1.log",force=true)
    rm("exam_spanish_1.out",force=true)
    rm("results.csv",force=true)
    rm("results_examio.csv",force=true)
end
