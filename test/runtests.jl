using Exams
using Test

@testset "basic-latex-installation" begin
    filename = "../assets/hello.tex"
    @test isfile(filename)
    pdflatex = `lualatex $(filename)`
    run(pdflatex)
    run(pdflatex)
    @test isfile("hello.pdf")
    rm("hello.pdf")
    rm("hello.aux")
    rm("hello.log")
end

@testset "example" begin 
    include("example.jl") 
    generate_exam(1)
    @test isfile("exam_spanish_1.tex")
    @test isfile("exam_spanish_1.pdf")
    rm("exam_spanish_1.pdf",force=true)
    rm("exam_spanish_1.tex",force=true)
    rm("results.csv",force=true)
    rm("results_examio.csv",force=true)
end
