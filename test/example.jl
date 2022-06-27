function generate_exam(nump)

    # Optional call, "spanish" by default, "catalan" and "engish" also available
    # set_language("spanish") 
    # Optional call, "exam" by default, any string possible
    # set_prefix("exam")
    # Define text to print
    headings["spanish"]["course_title"] = "Mecánica 1 (M1)"
    headings["spanish"]["exam_title"] = "Primer parcial"
    headings["spanish"]["exam_date"] = "01/01/2000"

    headings["catalan"]["course_title"] = "Mecànica 1 (M1)"
    headings["catalan"]["exam_title"] = "Primer parcial"
    headings["catalan"]["exam_date"] = "01/01/2000"

    headings["english"]["course_title"] = "Mechanics 1 (M1)"
    headings["english"]["exam_title"] = "First test"
    headings["english"]["exam_date"] = "01/01/2000"

    headings["spanish"]["graphics_path"] = "{../assets/}"
    headings["catalan"]["graphics_path"] = "{../assets/}"
    headings["english"]["graphics_path"] = "{../assets/}"

    mass=[1kg,2kg];
    h0=[1m,2m];
    v0=[1m/s,2m/s];
    vars_free_fall=collect(Iterators.take(Iterators.product(mass,h0,v0),nump))

    vars=(vars_free_fall,)
    sols=(free_fall,)

    generate_permutations(vars,sols)

end

function free_fall(vars,vars_out)

    (mass,h0,v0)=vars
    (mass_out,h0_out,v0_out)=vars_out
    g=9.81m/s^2
    g_out=var2latex(g,"m/s^2")

    #h=h0+v0*t-0.5*g*t^2
    t=2*v0/g+sqrt(v0^2+2*g*h0)/g
    v=v0-g*t
    P=mass*g

    if language=="spanish" 
        problem = "Un cuerpo de masa $mass_out es lanzado hacia arriba desde una altura $h0_out a una velocidad $v0_out. La aceleración local de la gravedad es $g_out. Determinar: \\\\ \n"
        question1 = quest2latex("el tiempo que tarda en caer al suelo (en unitname),", t,"s");
        question2 = quest2latex("la velocidad que alcanza al tocar el suelo (en unitname),", v,"km/h");
        question3 = quest2latex("el peso del cuerpo (en unitname).", P,"N");
    elseif language=="catalan"
        problem = "Un cos de massa $mass_out és llançat cap amunt des d'una alçada $h0_out a una velocitat $v0_out. L'acceleració local de la gravetat és $g_out. Determinar: \\\\ \n"
        question1 = quest2latex("el temps que triga a caure a terra (en unitname),", t,"s");
        question2 = quest2latex("la velocitat que arriba a tenir al tocar a terra (en unitname),", v,"km/h");
        question3 = quest2latex("el pes del cos (en unitname).", P,"N");
    elseif language=="english"
    end
    #figure = printfig(0.3,"fig:caidalibre","Cuerpo en caída libre","ball");
    figure = printfig_wrapped(0.3,"fig:caidalibre","Cuerpo en caída libre","ball");
    problem = problem*figure*question1*question2*question3
    return problem

end

