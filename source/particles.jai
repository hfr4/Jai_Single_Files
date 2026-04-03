ApplicationTitle  :: "Particles";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    round_texture = LoadTexture("assets/particles/round.png");
    pixel_texture = LoadTexture("assets/particles/pixel.png");

    {
        using my_emitter0;
        texture = *round_texture;

        production_zone.point = ApplicationCenter();;

        particles_per_second = 10;

        min_color = ColorToVector4(.YELLOW);
        max_color = ColorToVector4(.RED);

        min_scale = 1.0;
        max_scale = 3.0;

        min_speed = 100.0;
        max_speed = 200.0;

        min_drag = 0.0;
        max_drag = 0.03;

        min_theta = 0.7 * TAU;
        max_theta = 0.8 * TAU;

        min_lifetime = 2.0;
        max_lifetime = 2.0;

        fadein_period  = 0.1;
        fadeout_period = 0.3;

        gravity = { 0.0, 100 };
    }
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Down(.MOUSE_BUTTON_LEFT) {
        my_emitter0.producing = true;
        my_emitter0.production_zone.point = MousePositionOnApplication();
    } else {
        my_emitter0.producing = false;
    }

    if Pressed(.MOUSE_BUTTON_RIGHT) {
        using emitter := array_add(*my_emitters);
        texture   = *pixel_texture;
        production_zone.kind   = Circle;
        production_zone.circle = MakeCircle(MousePositionOnApplication(), 20);
        particles_per_second = 100;
        lifetime  = 2.0;
        gravity   = { 0.0, -700 };
        min_color = ColorToVector4(.BLUE);
        max_color = ColorToVector4(.CYAN);
        min_lifetime = 0.7;
        max_lifetime = 1.1;
    }
}

ApplicationUpdate :: (dt: float) {
    Update(*my_emitter0, dt);

    for * my_emitters {
        Update(it, dt);
        if !it.producing && !it.particles.count remove it;
    }
}

ApplicationRender :: () {
    PushColor(.2, .1, .3);
    DrawRectangle(ApplicationRectangle());

    for my_emitters DrawEmitter(it);
    DrawEmitter(my_emitter0);
}

round_texture : Texture;
pixel_texture : Texture;

my_emitter0 : Particle_Emitter;

my_emitters : [..] Particle_Emitter;
