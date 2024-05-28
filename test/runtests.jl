using Exams
using Test

@testset "example" begin 
    include("example.jl") 
    generate_exam(1)
    @test isfile("PrintedExamTest_spanish_1.tex")
    @test isfile("PrintedExamTest_spanish_1.pdf")
    rm("PrintedExamTest_spanish_1.pdf",force=true)
    rm("PrintedExamTest_spanish_1.tex",force=true)
    rm("PrintedExamTest_results.csv",force=true)
    rm("PrintedExamTest.bson",force=true)

    include("example_moodle.jl")
    generate_quiz(2)
    @test isfile("OnlineExamTest_spanish.tex")
    @test isfile("OnlineExamTest_spanish.pdf")
    rm("OnlineExamTest_spanish.pdf",force=true)
    rm("OnlineExamTest_spanish.tex",force=true)
    rm("OnlineExamTest_spanish-moodle.xml",force=true)
end
