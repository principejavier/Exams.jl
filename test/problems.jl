function free_fall(mass,h0,v0,language=nothing,format=nothing)

    mass_out=var2out(mass)
    h0_out=var2out(h0)
    v0_out=var2out(v0)
    g=9.81m/s^2
    g_out=var2out(g,"m/s^2")

    #h=h0+v0*t-0.5*g*t^2
    t=2*v0/g+sqrt(v0^2+2*g*h0)/g
    v=v0-g*t

    if language==SPA 
        statement = "Un cuerpo de masa $mass_out es lanzado hacia arriba desde una altura $h0_out a una velocidad $v0_out. La aceleración local de la gravedad es $g_out. Determinar:"
        figure1 = figure("ball","fig:caidalibre","Cuerpo en caída libre");
        question1 = question(format,"el tiempo que tarda en caer al suelo (en unitname),", t,"s");
        question2 = question(format,"la velocidad que alcanza al tocar el suelo (en unitname),", v,"km/h");
    elseif language==CAT
        statement = "Un cos de massa $mass_out és llançat cap amunt des d'una alçada $h0_out a una velocitat $v0_out. L'acceleració local de la gravetat és $g_out. Determinar:"
        question1 = question(format,"el temps que triga a caure a terra (en unitname),", t,"s");
        question2 = question(format,"la velocitat que arriba a tenir al tocar a terra (en unitname),", v,"km/h");
    elseif language==ENG
    else
        println("mass = ",mass)
        println("h0 = ",h0)
        println("v0 = ",v0)
        println("v = ",v)
        println("t = ",t)
        return nothing
    end
    return [statement,figure1,question1,question2]

end

function inclined_plane(mass,α,language=nothing,format=Unformatted)

    mass_out=var2out(mass)
    α_out=var2out(α,"\\alpha","°")
    g=9.81m/s^2
    g_out=var2out(g,"m/s^2")

    Fx=mass*g*sin(α)
    Fy=mass*g*cos(α)
    a=g*sin(α)

    if language==SPA 
        statement = "Un bloque de $mass_out desliza sobre un plano cuyo ángulo de inclinación es $α_out. Considerando $g_out, determinar:"
        question1=question(format,"la componente paralela de la fuerza debida a la gravedad en unitname",Fx,"N")
        question2=question(format,"la componente normal de la fuerza debida a la gravedad en unitname",Fy,"N")
        question3=question(format,"la aceleración del bloque suponiendo una superficie sin fricción en unitname.",a,"m/s^2")
    elseif language==CAT
        statement = "Un bloc de $mass_out llisca sobre un pla que té un angle d'inclinació de $α_out. Considerant $g_out, determinar:"
        question1=question(format,"la component paral·lela de la força deguda a la gravetat en unitname",Fx,"N")
        question2=question(format,"la component normal de la força deguda a la gravetat en unitname",Fy,"N")
        question3=question(format,"l'acceleració del bloc suposant una superfície sense fricció en unitname.",a,"m/s^2")
    elseif language==ENG
        statement = "A $mass_out block is sitting on an incline plane whose angle of inclination is $α_out. Considering $g_out, determine:"
        question1=question(format,"the parallel component of the force due to gravity in unitname,",Fx,"N")
        question2=question(format,"the normal component of the force due to gravity in unitname,",Fy,"N")
        question3=question(format,"the block’s acceleration assuming a frictionless surface in unitname.",a,"m/s^2")
    else
        println(mass,α)
    end
    return [statement,question1,question2,question3]

end

function theory_questions(language=nothing,format=Unformatted)

    eq = Vector{String}(undef,5);
    eq[1]="F=m*a"    # this the correct one, it will be shuffled when generating permutations
    eq[2]="F=m*a^2"
    eq[3]="F=m*g"
    eq[4]="F=m/a"
    eq[5]="F=m^2*a"

    if language==SPA 
        statement = "Teoría de la mecánica clásica."
        question1=question(format,"La ley de Newton se puede escribir como:",eq)
    elseif language==CAT
        statement = "Teoria de la mecànica clàssica."
        question1=question(format,"La llei de Newton es pot escriure com:",eq)
    elseif language==ENG
        statement = "Theory of classical mechanics."
        question1=question(format,"The Newton law can be written as,",eq)
    end
    return [statement,question1]

end