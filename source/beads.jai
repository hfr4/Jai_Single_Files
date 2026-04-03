ApplicationTitle  :: "Beads";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    Init(*my_solver);
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Down(.MOUSE_BUTTON_LEFT) {
        now := seconds_since_init();
        mp  := MousePositionOnApplication();

        MAX_PARTICLES_COUNT :: 1000;
        TIME_BETWEEN_PARTICLE_GENERATION :: 0.2;

        can_generate := last_generation_time == 0.0 || now - last_generation_time > TIME_BETWEEN_PARTICLE_GENERATION;
        can_generate &&= my_solver.particles.count < MAX_PARTICLES_COUNT;
        can_generate &&= Colliding(mp, my_solver.constraint);

        if can_generate {
            MIN_RADIUS :: 10.0;
            MAX_RADIUS :: 20.0;

            using particle := array_add(*my_solver.particles);
            position     = mp;
            old_position = mp;
            radius       = RandomFloat(MIN_RADIUS, MAX_RADIUS);
            color        = RainbowColor(xx now);

            last_generation_time = now;
        }
    }
}

ApplicationUpdate :: (dt: float) {
    Update(*my_solver, dt / 10.0);
}

ApplicationRender :: () {
    {
        PushColor({ .05, .05, .05, 1 });
        DrawCircle(my_solver.constraint);
    }

    for my_solver.particles {
        PushColor(it.color);
        DrawCircle({ it.position.x, it.position.y, it.radius });
    }
}

my_solver : Solver;
last_generation_time : float64;

Solver :: struct {
    particles  : [..] Bead;
    sub_steps  : int = 1;
    constraint : Circle;
}

Init :: (using solver: *Solver) {
    constraint = MakeCircle(ApplicationCenter(), 450.0 );
    sub_steps  = 8;
}

Update :: (using solver: *Solver, dt: float) {
    step_dt := dt / sub_steps;

    for 1..sub_steps {
        ApplyGravity(solver);
        CheckCollisions(solver, step_dt);
        ApplyContraint(solver);
        for * particles Update(it, dt);
    }
}

CheckCollisions :: (using solver: *Solver, dt: float) {
    RESPONSE_COEF :: 0.75;

    for i: 0..particles.count - 2 {
        p0 := *particles[i];

        for j: i + 1..particles.count - 1 {
            p1 := *particles[j];

            vector   := p0.position - p1.position;
            dist2    := vector.x * vector.x + vector.y * vector.y;
            min_dist := p0.radius + p1.radius;

            if dist2 < min_dist * min_dist {
                dist         := sqrt(dist2);
                n            := vector / dist;
                mass_ratio_1 := p0.radius / (p0.radius + p1.radius);
                mass_ratio_2 := p1.radius / (p0.radius + p1.radius);
                delta        := 0.5 * RESPONSE_COEF * (dist - min_dist);

                p0.position -= n * (mass_ratio_2 * delta);
                p1.position += n * (mass_ratio_1 * delta);
            }
        }
    }
}

ApplyGravity :: (using solver: *Solver) {
    GRAVITY :: Vector2.{ 0.0, 980 };

    for * particles {
        it.velocity += GRAVITY;
    }
}

ApplyContraint :: (using solver: *Solver) {
    for * particles {
        vector := Center(constraint) - it.position;
        dist   := sqrt(vector.x * vector.x + vector.y * vector.y);

        if dist < constraint.r - it.radius continue;

        n := vector / dist;
        it.position = Center(constraint) - n * (constraint.r - it.radius);
    }
}

Bead :: struct {
    position     : Vector2;
    old_position : Vector2;
    velocity     : Vector2;
    radius       : float;
    color        : Vector4;
}

Update :: (using particle: *Bead, dt: float) {
    diff := position - old_position;
    old_position = position;
    position += diff + velocity * (dt * dt);
    velocity = {};
}

Accelerate :: (using particle: *Bead, a: Vector2) {
    velocity += a;
}

RainbowColor :: (t: float) -> Vector4 {
    r := sin(t);
    g := sin(t + 0.33 * TAU);
    b := sin(t + 0.66 * TAU);
    return { r * r, g * g, b * b, 1 };
}