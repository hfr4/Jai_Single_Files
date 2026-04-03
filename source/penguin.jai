ApplicationTitle  :: "Penguin";
ApplicationWidth  :: 1200;
ApplicationHeight :: 450;

// Bug : Penguin keep the same angle when having shield powerup ?

ApplicationInit :: () {
    pixel_texture = LoadTexture("assets/penguin/pixel.png");
    star_texture  = LoadTexture("assets/penguin/star.png");

    font_48 = LoadFont("assets/font.ttf", 48);
    font_24 = LoadFont("assets/font.ttf", 24);
    font_16 = LoadFont("assets/font.ttf", 16);
}

ApplicationReset :: () {
    ChangeRandomSeed();

    penguin = .{
        state          = .LAUNCH,
        position       = .{ PENGUIN_X, PENGUIN_Y },
        radius         = PENGUIN_R,
        angle          = 0.0,
        velocity       = .{ 0.0, 0.0 },

        float_timer    = 0,
        bounce_timer   = 0,
        glide_stamina  = GLIDE_MAX_STAMINA,
        launch_charges = 0,

        is_floating    = false,
        is_bouncing    = false,
        is_gliding     = false,
    };

    power_indicator = .{ POWER_MIN, 1 };
    angle_indicator = .{ ANGLE_MIN, 1 };

    my_camera.translation = { 0, 0 };


    gravity = BASE_GRAVITY;

    score = 0;

    array_reset(*obstacles);
    array_reset(*powerups);
    array_reset(*background_objects);

    GenerateObjects();
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.SPACEBAR) {
        if penguin.state == .LAUNCH || penguin.state == .RELAUNCH
        {
            if penguin.state == .RELAUNCH {
                penguin.launch_charges -= 1;
            }

            penguin.velocity.x =  power_indicator.value * cos(angle_indicator.value);
            penguin.velocity.y = -power_indicator.value * sin(angle_indicator.value);

            penguin.state = .FLYING;
        }
        else if penguin.state == .FLYING || penguin.state == .SLIDING
        {
            if penguin.glide_stamina > 0 {
                penguin.is_gliding = true;
            }
        }
    }

    if Pressed("R") {
        if penguin.state != .LANDED && penguin.state != .RELAUNCH && penguin.launch_charges > 0 {
            power_indicator.value     = POWER_MIN;
            power_indicator.direction = 1;

            angle_indicator.value     = ANGLE_MIN;
            angle_indicator.direction = 1;

            penguin.angle = 0;
            penguin.state = .RELAUNCH;
        }
    }

    if Pressed(.MOUSE_BUTTON_LEFT) {
        if penguin.state == .LANDED {
            center := ApplicationCenter();;
            half   := Vector2.{ 150, 50 };
            replay_rect := BoundingBox(center - half, center + half);

            if Colliding(MousePositionOnApplication(), replay_rect) {
                Reset();
            }
        }
    }

    if Released(.SPACEBAR) {
        penguin.is_gliding = false;
    }
}

ApplicationUpdate :: (dt: float) {
    for * particle_emitters {
        Update(it, dt);

        if it.producing == false && it.particles.count == 0 {
            remove it;
        }
    }

    // Float power up, don't update while relaunching
    if penguin.is_floating && penguin.state != .RELAUNCH {
        penguin.float_timer -= 1;
        if penguin.float_timer <= 0 {
            penguin.is_floating = false;
            gravity = BASE_GRAVITY;
        }
    }

    if penguin.is_bouncing {
        penguin.bounce_timer -= 1;
        if penguin.bounce_timer <= 0 {
            penguin.is_bouncing = false;
        }
    }

    // Activate glide when sliding
    if penguin.is_gliding && penguin.state == .SLIDING {
        penguin.velocity.y = -GLIDE_LIFT_POWER_FROM_GROUND;
        penguin.state = .FLYING;
    }

    if penguin.state == .LAUNCH || penguin.state == .RELAUNCH
    {
        power_indicator.value += POWER_SPEED * power_indicator.direction;
        if power_indicator.value < POWER_MIN || power_indicator.value > POWER_MAX {
            power_indicator.direction *= -1;
            Clamp(*power_indicator.value, POWER_MIN, POWER_MAX);
        }

        angle_indicator.value += ANGLE_SPEED * angle_indicator.direction;
        if angle_indicator.value < ANGLE_MIN || angle_indicator.value > ANGLE_MAX {
            angle_indicator.direction *= -1;
            Clamp(*angle_indicator.value, ANGLE_MIN, ANGLE_MAX);
        }
    }
    else if penguin.state == .FLYING
    {
        penguin.velocity.y += gravity;

        // Glide
        if penguin.is_gliding {
            penguin.velocity.y    -= GLIDE_LIFT_POWER;
            penguin.glide_stamina -= GLIDE_STAMINA_DEPLETION_RATE;

            if penguin.glide_stamina <= 0 {
                penguin.glide_stamina = 0;
                penguin.is_gliding    = false;
            }
        }

        penguin.position += penguin.velocity;
        penguin.angle = atan2(penguin.velocity.y, penguin.velocity.x);

        ResolveCollisions();

        if penguin.position.y + penguin.radius >= GROUND_Y {
            penguin.position.y = GROUND_Y - penguin.radius;

            if abs(penguin.velocity.y) > MIN_BOUNCE_VELOCITY {
                penguin.velocity.x *= (FRICTION + BOUNCE_DAMPING) / 2;
                penguin.velocity.y *= -BOUNCE_DAMPING;

                penguin.is_bouncing  = true;
                penguin.bounce_timer = BOUNCE_DURATION;

                // Ground particle
                e := array_add(*particle_emitters);
                e.texture   = *pixel_texture;
                /*
                e.min_color = WHITE;
                e.max_color = WHITE;
                e.position  = penguin.position;
                e.speed     = .{ 200 , 300 };
                e.lifetime  = .1;
                e.particles_per_second = 200;
                */
            } else {
                penguin.velocity.y = 0;
                if abs(penguin.velocity.x) > MIN_SLIDE_SPEED {
                    penguin.state = .SLIDING;
                } else {
                    penguin.velocity.x = 0;
                    penguin.state = .LANDED;
                }
            }
        }
    }
    else if penguin.state == .SLIDING
    {
        penguin.velocity.x *= FRICTION;
        penguin.position.x += penguin.velocity.x;

        penguin.angle += penguin.velocity.x * .05; // Roll

        ResolveCollisions();

        if abs(penguin.velocity.x) < MIN_SLIDE_SPEED {
            penguin.velocity.x = 0;
            penguin.state = .LANDED;
        }
    }

    // Camera
    if penguin.position.x > ApplicationRectangle().w / 2.0 {
        targetX := penguin.position.x - ApplicationRectangle().w / 2.5;
        my_camera.translation.x += (targetX - my_camera.translation.x) * 0.1;
    }

    // Score
    score = cast(int) max(0.0, floor((penguin.position.x - PENGUIN_X) / 10));
    if penguin.state == .LANDED {
        high_score = max(score, high_score);
    }
}

ApplicationRender :: () {
    // Background
    {
        color := Vector4.{ 0.52, 0.80, 0.92, 1.0 };
        PushColor(color);
        DrawRectangle(ApplicationRectangle());
    }

    // Ground
    {
        rect  := Rectangle.{ 0, xx GROUND_Y, xx ApplicationRectangle().w, xx GROUND_H };
        color := Vector4.{ 1.0, 1.0, 1.0, 1.0 };

        PushColor(color);
        DrawRectangle(rect);
    }
    // Background objects
    {
        {
            PushTranslation(-my_camera.translation.x * .2, my_camera.translation.y);
            for background_objects {
                if it.layer == .BACKGROUND {
                    if it.kind == .MOUNTAIN {
                        PushTranslation(it.x, it.y);
                        PushMode(.FILL);
                        PushColor({ .2, .2, .4, 1.0 });
                        DrawPolygon(Vector2.[ { 400, 0   }, { 0, -400 }, { -400, 0   } ]);

                        PushColor({ .8, .8, .8, 1.0 });
                        DrawPolygon(Vector2.[ { 50 ,-350 }, { 0, -400 }, { -50 ,-350 } ]);
                    }
                }
            }
        }

        {
            PushTranslation(-my_camera.translation.x * .6, my_camera.translation.y);
            for background_objects {
                if it.layer == .MIDDLEGROUND {
                    if it.kind == .MOUNTAIN {
                        PushTranslation(it.x, it.y);
                        PushMode(.FILL);
                        PushColor({ .5, .5, .7, 1.0 });
                        DrawPolygon({ .[ { 250 , 0 }, { 0 , -250 }, { -250, 0 } ] });
                    }
                }
            }
        }

        {
            PushTranslation(-my_camera.translation.x * .8, my_camera.translation.y);
            for background_objects {
                if it.layer == .FOREGROUND {
                    if it.kind == .MOUNTAIN {
                        for background_objects {
                            PushTranslation(it.x, it.y);
                            PushMode(.FILL);
                            PushColor({ .8, .8, .9, 1.0 });
                            DrawPolygon({ .[ { 100 , 0 }, { 0 , -100 }, { -100, 0 } ] });
                        }
                    }
                }
            }
        }
    }


    {
        PushCamera(my_camera);

        for obstacles {
            if it.kind == {
                case .SNOWDRIFT;
                    PushColor({ 0.91, 0.96, 1.0, 1.0 });
                    DrawRectangle(it.rectangle);

                case .WALL;
                    PushColor({ 0.47, 0.66, 0.42, 1.0 });
                    DrawRectangle(it.rectangle);
            }
        }

        for powerups {
            if !it.active continue;

            if it.kind == {
                case .BOOST;
                    color := Vector4.{ 0.0, 0.8, 0.2, 1.0 };

                    PushColor(color);
                    DrawRectangle(it.rectangle);

                    arrow_head: [3] Vector2;
                    arrow_head[0] = Vector2.{ R(it.rectangle), CY(it.rectangle) } + Vector2.{ 0 , -20 };
                    arrow_head[1] = Vector2.{ R(it.rectangle), CY(it.rectangle) } + Vector2.{ 20,  0  };
                    arrow_head[2] = Vector2.{ R(it.rectangle), CY(it.rectangle) } + Vector2.{ 0 ,  20 };

                    PushMode(.FILL);
                    DrawPolygon({ arrow_head });

                case .FLOAT;
                    t : Transform;
                    t.translation = Center(it.circle);
                    t.rotation    = PI / 4.0;
                    PushTransform(t);

                    PushColor({ 96 / 255.0, 165 / 255.0, 250 / 255.0, 1.0 });
                    DrawEllipse({ 0.0, 0.0 , it.circle.r * 0.7, it.circle.r});

                case .LAUNCH_CHARGE;
                    t : Transform;
                    t.translation = Center(it.circle);
                    t.scaling     = { 1.5, 1.5 };
                    PushTransform(t);
                    PushAlignment(.CENTER);
                    DrawTexture(star_texture);

                case .GLIDE_REFILL;
                    PushColor({ 1.0, 0.0, 1.0, 1.0 });
                    DrawCircle(it.circle);
            }
        }

        YETI_RECTANGLE :: Rectangle.{ 80, 340, 40, 60 };

        // Yeti
        {
            // Body
            {
                PushColor({ .54, .27, .07, 1.0 });
                DrawRectangle(YETI_RECTANGLE);
            }

            // Head
            {
                t : Transform;
                t.translation = { CX(YETI_RECTANGLE), YETI_RECTANGLE.y - 10 };
                t.rotation    = .4;
                PushTransform(t);

                PushColor({ .54, .27, .07, 1.0 });
                DrawCircle({ 0, 0, YETI_RECTANGLE.w / 3 });

                PushColor(.WHITE);
                DrawCircle({ -5, 0, 2 });
                DrawCircle({  5, 0, 2 });
            }
        }

        // Indicators
        if penguin.state == .LAUNCH || penguin.state == .RELAUNCH {
            // Power bar
            {
                w : float = 15;
                h : float = 60;
                x : float = ifx penguin.state == .RELAUNCH then penguin.position.x - 45     else YETI_RECTANGLE.x - 30;
                y : float = ifx penguin.state == .RELAUNCH then penguin.position.y - h / 2  else YETI_RECTANGLE.y;

                percent := power_indicator.value / POWER_MAX;
                PushColor({ 229 / 255.0, 231 / 255.0, 235 / 255.0, 1 });
                DrawRectangle({ x, y, w, h });

                PushColor({ 239 / 255.0, 68  / 255.0, 68  / 255.0, 1 });
                DrawRectangle({ x, y + (h - h * percent), w, h * percent });
            }

            // Angle bar
            {
                s0 := MakeSegmentFromPolar(penguin.position, -angle_indicator.value, 20);
                s1 := MakeSegmentFromPolar(penguin.position, -angle_indicator.value, 50);

                PushColor(.BLACK);
                PushWidth(3);
                DrawSegment({ s0.b, s1.b });
            }
        }

        DrawPenguin(penguin.position);

        // Out of bound penguin indicator
        if penguin.position.y < -penguin.radius {
            DrawPolygon({ .[ .{ penguin.position.x - 15, 20 }, .{ penguin.position.x + 15, 20 }, .{ penguin.position.x, 5 }] });
            DrawCircle({ penguin.position.x, 55, 30 });
            DrawPenguin({ penguin.position.x, 55 });
        }

        // Particles
        {
            // for particle_emitters Draw(it);
        }

    }




    // Ui
    {
        // Glide stamina
        {
            percent := (penguin.glide_stamina / GLIDE_MAX_STAMINA);

            w : float = 500;
            h : float = 25;
            x : float = (ApplicationRectangle().w / 2) - (w / 2);
            y : float = GROUND_Y + (GROUND_H / 2) - (h / 2);

            PushColor({ 0.0, 0.0, 0.0, 1.0 });
            DrawRectangle({ x, y, w, h });

            PushColor({ 1.0, 0.0, 0.0, 1.0 });
            DrawRectangle({ x, y, w * percent, h });
        }

        // Replay screen
        if penguin.state == .LANDED {
            PushColor({ 0.0, 0.0, 0.0, 0.6 });
            DrawRectangle(ApplicationRectangle());

            center      := ApplicationCenter();;
            half        := Vector2.{ 150, 50 };
            replay_rect := BoundingBox(center - half, center + half);

            mp    := MousePositionOnApplication();
            color : Color = ifx Colliding(mp, replay_rect) then .RED else .WHITE;

            {
                PushTranslation(ApplicationCenter());
                PushAlignment(.CENTER);

                {
                    PushTranslation(-5.0, -5.0);
                    PushColor(.RED);
                    PushAlignment(.CENTER);
                    DrawText(*font_48, "Replay ?");
                }

                {
                    PushColor(color);
                    PushAlignment(.CENTER);
                    DrawText(*font_48, "Replay ?");
                }
            }
        }

        // Score
        {
            color : Color = ifx penguin.state == .LANDED then .WHITE else .BLACK;

            {
                PushTranslation(10, 24);

                {
                    PushTranslation(-2.0, -2.0);
                    PushColor(.RED);
                    DrawText(*font_24, "Score : %", score);
                }

                {
                    PushColor(color);
                    DrawText(*font_24, "Score : %", score);
                }
            }

            {
                PushTranslation(ApplicationRectangle().w - 10, 24);
                PushAlignment(.TR);

                {
                    PushTranslation(-2.0, -2.0);
                    PushColor(.RED);
                    DrawText(*font_24, "HiScore : %", high_score);
                }

                {
                    PushColor(color);
                    DrawText(*font_24, "HiScore : %", high_score);
                }
            }
        }

        // Relaunch button
        if penguin.launch_charges > 0 {
            h : float = 25;
            y : float = GROUND_Y + (GROUND_H / 2) - (h / 2);
            w : float = 100;
            x : float = ApplicationRectangle().w - w - 20;

            r := Rectangle.{ x, y, w, h };

            PushColor({ 1.0, 1.0, 0.0, 1.0 });
            DrawRectangle(r);

            PushAlignment(.CENTER);
            PushColor(.BLACK);
            PushTranslation(Center(r));
            DrawText(*font_16, "Relaunch x%", penguin.launch_charges);
        }
    }

}

GenerateObjects :: () {
    // PowerUps
    {
        obj_count   := 35;
        min_spacing := 380;
        max_spacing := 800;

        for i: 0..obj_count - 1 {
            x := PENGUIN_X + 700 + i * (min_spacing + RandomFloat() * (max_spacing - min_spacing));

            roll := RandomFloat();
            if      roll < 1/4.0  array_add(*powerups, .{ kind = .BOOST        , rectangle = .{ x, GROUND_Y - (30 + RandomFloat() * 120), 50, 20 }         , active = true });
            else if roll < 2/4.0  array_add(*powerups, .{ kind = .FLOAT        , circle    = .{ x + RandomFloat() * 20, GROUND_Y - (50 + RandomFloat() * 100), 15 }, active = true });
            else if roll < 3/4.0  array_add(*powerups, .{ kind = .LAUNCH_CHARGE, circle    = .{ x + RandomFloat() * 20, GROUND_Y - (40 + RandomFloat() * 90) , 18 }, active = true });
            else                  array_add(*powerups, .{ kind = .GLIDE_REFILL , circle    = .{ x + RandomFloat() * 20, GROUND_Y - (30 + RandomFloat() * 120), 16 }, active = true });
        }
    }

    // Obstacles
    {
        obj_count   := 70;
        min_spacing := 500;
        max_spacing := 1000;

        for i: 0..obj_count - 1 {
            x := PENGUIN_X + 700 + i * (min_spacing + RandomFloat()  * (max_spacing - min_spacing));

            roll := RandomFloat();
            if roll < 1.5/2.0 array_add(*obstacles, .{ kind = .WALL      , rectangle = .{ x, GROUND_Y - (20 + RandomFloat() * 80), 20 + RandomFloat()  * 30, 40 + RandomFloat()  * 100 } });
            else              array_add(*obstacles, .{ kind = .SNOWDRIFT , rectangle = .{ x, GROUND_Y - (10 + RandomFloat() * 20), 80 + RandomFloat()  * 70, 20 + RandomFloat()  * 30  } });
        }
    }

    // Background objects
    {
        obj_count := 35;

        for i: 0..obj_count - 1 {
            min_spacing := 800;
            max_spacing := 2000;
            x := PENGUIN_X + 700 + i * (min_spacing + RandomFloat()  * (max_spacing - min_spacing));
            array_add(*background_objects, .{ .BACKGROUND, .MOUNTAIN, .{ x + RandomFloat() * 20, GROUND_Y } });
        }

        for i: 0..obj_count - 1 {
            min_spacing := 800;
            max_spacing := 2000;
            x := PENGUIN_X + 700 + i * (min_spacing + RandomFloat()  * (max_spacing - min_spacing));
            array_add(*background_objects, .{ .MIDDLEGROUND, .MOUNTAIN, .{ x + RandomFloat() * 20, GROUND_Y } });
        }

        for i: 0..obj_count - 1 {
            min_spacing := 500;
            max_spacing := 1000;
            x := PENGUIN_X + 700 + i * (min_spacing + RandomFloat()  * (max_spacing - min_spacing));
            array_add(*background_objects, .{ .FOREGROUND, .MOUNTAIN, .{ x + RandomFloat() * 20, GROUND_Y } });
        }
    }
}

ResolveCollisions :: () {
    penguin_circ := Circle.{ penguin.position.x, penguin.position.y, penguin.radius };

    for obstacles {
        if Colliding(penguin_circ, it.rectangle) {
            if it.kind == {
                case .WALL;
                    overlapX := (penguin.radius + it.rectangle.w / 2) - abs(penguin.position.x - CX(it.rectangle));
                    overlapY := (penguin.radius + it.rectangle.h / 2) - abs(penguin.position.y - CY(it.rectangle));

                    if overlapX < overlapY {
                        penguin.velocity.x *= -0.5;
                        penguin.position.x = ifx penguin.position.x < CX(it.rectangle) then L(it.rectangle) - penguin.radius - 1 else R(it.rectangle) + penguin.radius + 1;
                    } else {
                        penguin.velocity.y *= -0.5;
                        penguin.position.y = ifx penguin.position.y < CY(it.rectangle) then T(it.rectangle) - penguin.radius - 1 else B(it.rectangle) + penguin.radius + 1;
                    }

                    penguin.is_bouncing  = true;
                    penguin.bounce_timer = BOUNCE_DURATION;

                case .SNOWDRIFT;
                    penguin.velocity.x *= 0.85;
                    if abs(penguin.velocity.y) > 0.1 penguin.velocity.y *= 0.9;
            }
        }
    }

    for * powerups {
        if !it.active continue;

        collided := false;
        if it.kind == .BOOST {
            if Colliding(penguin_circ, it.rectangle) collided = true;
        } else {
            if Colliding(penguin_circ, it.circle)    collided = true;
        }

        if collided {
            it.active = false;

            if it.kind == {
                case .BOOST;
                    penguin.velocity.x += BOOST_VALUE;
                    if penguin.velocity.y < 0 penguin.velocity.y -= BOOST_VALUE / 3;

                case .FLOAT;
                    penguin.is_floating = true;
                    penguin.float_timer = FLOAT_DURATION;
                    gravity             = BASE_GRAVITY * FLOAT_GRAVITY_MULTIPLIER;

                case .LAUNCH_CHARGE;
                    penguin.launch_charges += 1;

                case .GLIDE_REFILL;
                    penguin.glide_stamina = min(GLIDE_MAX_STAMINA, penguin.glide_stamina + GLIDE_REFILL_AMOUNT);
            }
        }
    }
}

penguin : struct {
    State :: enum {
        LAUNCH;
        RELAUNCH;
        FLYING;
        SLIDING;
        LANDED;
    }
    state : State;

    position       : Vector2;
    radius         : float;
    angle          : float;
    velocity       : Vector2;

    float_timer    : int;
    bounce_timer   : int;
    glide_stamina  : float;
    launch_charges : int;

    is_floating    : bool;
    is_bouncing    : bool;
    is_gliding     : bool;
}

power_indicator : struct {
    value     : float;
    direction : int;
}

angle_indicator : struct {
    value     : float;
    direction : int;
}

obstacles          : [..] Obstacle;
powerups           : [..] Power_Up;
background_objects : [..] Background_Object;
particle_emitters  : [..] Particle_Emitter;

pixel_texture : Texture;
star_texture  : Texture;

font_48: Font;
font_24: Font;
font_16: Font;

my_camera : Camera;

gravity : float;

score      : int;
high_score : int;

GROUND_H     :: 50;
GROUND_Y     :: 400;

PENGUIN_X    :: 140;
PENGUIN_Y    :: 385;
PENGUIN_R    :: 15;

BASE_GRAVITY :: 0.25;

POWER_MIN    :: 10.0;
POWER_MAX    :: 25.0;
POWER_SPEED  :: 0.4;

ANGLE_MIN    :: 5  * (PI / 180);
ANGLE_MAX    :: 80 * (PI / 180);
ANGLE_SPEED  :: 1  * (PI / 180);

FRICTION            :: 0.985;
BOUNCE_DAMPING      :: 0.6;
MIN_SLIDE_SPEED     :: 0.1;
MIN_BOUNCE_VELOCITY :: 1.0;

FLOAT_DURATION           :: 180;
FLOAT_GRAVITY_MULTIPLIER :: 0.3;

BOUNCE_DURATION :: 15;

BOOST_VALUE :: 8;

GLIDE_MAX_STAMINA            :: 100.0;
GLIDE_STAMINA_DEPLETION_RATE :: 0.75;
GLIDE_LIFT_POWER             :: 0.4;
GLIDE_LIFT_POWER_FROM_GROUND :: 3.5;
GLIDE_REFILL_AMOUNT          :: 50;

Power_Up :: struct {
    Kind :: enum {
        BOOST;
        FLOAT;
        LAUNCH_CHARGE;
        GLIDE_REFILL;
    }
    kind : Kind;

    using collider : union {
        rectangle : Rectangle;
        circle    : Circle;
    }

    active : bool;
}

Obstacle :: struct {
    Kind :: enum {
        WALL;
        SNOWDRIFT;
    }
    kind : Kind;

    using collider : union {
        rectangle : Rectangle;
        circle    : Circle;
    }
}

Background_Object :: struct {
    Layer :: enum {
        FOREGROUND;
        MIDDLEGROUND;
        BACKGROUND;
    }

    Kind :: enum {
        MOUNTAIN;
    }

    layer : Layer;
    kind  :  Kind;
    using position : Vector2;
}

DrawPenguin :: (pos: Vector2) {
    t : Transform;
    t.translation = pos;
    t.rotation    = penguin.angle;
    PushTransform(t);

    if penguin.is_floating {
        PushColor({ 173 / 255.0, 216 / 255.0, 230 / 255.0, 0.7 });
        DrawCircle({ 0, 0, penguin.radius + 10 });
    }

    PushColor(.BLACK);
    DrawCircle({ 0, 0, penguin.radius });

    PushColor(.WHITE);
    DrawEllipse({ 0, 0 , penguin.radius - 5, penguin.radius - 3});

    // Beak
    {
        PushColor(.ORANGE);
        PushWidth(3);
        DrawSegment({ { 5, 1 }, { 20, 1 } });
    }

    // Eyes
    if penguin.is_bouncing {
        PushColor(.BLACK);
        PushWidth(2);

        l0 := Segment.{ .{ -6, -7 }, .{ -2,  0 } };
        l1 := Segment.{ .{ -6,  0 }, .{ -2, -7 } };
        DrawSegment(l0);
        DrawSegment(l1);

        r0 := Segment.{ .{ 2, -7 }, .{ 6,  0 } };
        r1 := Segment.{ .{ 2,  0 }, .{ 6, -7 } };
        DrawSegment(r0);
        DrawSegment(r1);

    } else if penguin.is_gliding {
        PushColor(.BLACK);
        PushWidth(2);

        l := Segment.{ .{ -8, -4 }, .{ -2, -4 } };
        r := Segment.{ .{  2, -4 }, .{  8, -4 } };
        DrawSegment(l);
        DrawSegment(r);
    } else {
        PushColor(.BLACK);

        DrawCircle({ -5, -4 , 2 });
        DrawCircle({  5, -4 , 2 });
    }

    // Wings
    if penguin.is_gliding {
        a := Vector2.{ -7, 3 };
        b := Vector2.{  3, 3 };
        c := Vector2.{ - 2, cast(float) sin(seconds_since_init() * 20.0) * 15.0 };

        PushMode(.FILL);
        PushColor(.WHITE);
        DrawPolygon(Vector2.[ a, b, c ]);

        PushMode(.LINE);
        PushColor(.BLACK);
        PushWidth(2);
        DrawPolygon(Vector2.[ a, b, c ]);
    }
}
