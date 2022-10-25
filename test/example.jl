function generate_exam(nump)

    headings=StandardHeadings

    headings[SPA]["CourseTitle"] = "Mecánica 1 (M1)"
    headings[CAT]["CourseTitle"] = "Mecànica 1 (M1)"
    headings[ENG]["CourseTitle"] = "Mechanics 1 (M1)"

    headings[SPA]["ExamTitle"] = "Primer parcial"
    headings[CAT]["ExamTitle"] = "Primer parcial"
    headings[ENG]["ExamTitle"] = "First test"
    
    headings[SPA]["ExamDate"] = "01/01/2000"
    headings[CAT]["ExamDate"] = "01/01/2000"
    headings[ENG]["ExamDate"] = "01/01/2000"

    headings[SPA]["GraphicsPath"] = "{../assets/}"
    headings[CAT]["GraphicsPath"] = "{../assets/}"
    headings[ENG]["GraphicsPath"] = "{../assets/}"

    exam = PrintedExam(nump,[SPA],headings)

    mass=[1kg,2kg];
    h0=[1m,2m];
    v0=[1m/s,2m/s];

    add_problem!(exam,WrappedFigure(0.25,-5mm),ALL2ALL,free_fall,mass,h0,v0)
    add_problem!(exam,FloatingFigure(0.3),ALL2ALL,free_fall,mass,h0,v0)

    return exam
end

function free_fall(mass,h0,v0,language=undef,format=undef)

    mass_out=var2latex(mass)
    h0_out=var2latex(h0)
    v0_out=var2latex(v0)
    g=9.81m/s^2
    g_out=var2latex(g,"m/s^2")

    #h=h0+v0*t-0.5*g*t^2
    t=2*v0/g+sqrt(v0^2+2*g*h0)/g
    v=v0-g*t
    P=mass*g

    if language==SPA 
        statement = "Un cuerpo de masa $mass_out es lanzado hacia arriba desde una altura $h0_out a una velocidad $v0_out. La aceleración local de la gravedad es $g_out. Determinar: \\\\ \n"
        figure1 = figure("ball","fig:caidalibre","Cuerpo en caída libre");
        question1 = question(format,"el peso del cuerpo (en unitname).", P,"N");
        question2 = question(format,"el tiempo que tarda en caer al suelo (en unitname),", t,"s");
        question3 = question(format,"la velocidad que alcanza al tocar el suelo (en unitname),", v,"km/h");
    elseif language==CAT
        statement = "Un cos de massa $mass_out és llançat cap amunt des d'una alçada $h0_out a una velocitat $v0_out. L'acceleració local de la gravetat és $g_out. Determinar: \\\\ \n"
        question1 = question(format,"el pes del cos (en unitname).", P,"N");
        question2 = question(format,"el temps que triga a caure a terra (en unitname),", t,"s");
        question3 = question(format,"la velocitat que arriba a tenir al tocar a terra (en unitname),", v,"km/h");
    elseif language==ENG
    else
        println(mass,h0,v0,P,v,t)
    end
    return [statement,figure1,question1,question2,question3]

end

