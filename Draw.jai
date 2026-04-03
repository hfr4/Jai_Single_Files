#add_context drawing_state : Drawing_State;

Drawing_State :: struct {
    color     := Vector4.{ 1, 1, 1, 1 };
    mode      := Drawing_Mode.FILL;
    align     := Drawing_Alignment.TL;
    width     := 1.0;
    transform := Matrix4_Identity;
    flip      : Flip_Flag;
}

Drawing_Mode :: enum {
    FILL;
    LINE;
}

Drawing_Alignment :: enum {
    TL; TR; BL; BR; TC; BC; CL; CR; CC;
    CENTER :: CC;
}

Flip_Flag :: enum_flags {
    VERTICAL;
    HORIZONTAL;
}

Color :: enum {
    WHITE  :: 0xFFFFFF;
    BLACK  :: 0x000000;
    GREY   :: 0x808080;
    RED	   :: 0xE61A33;
    GREEN  :: 0x00CC1A;
    CYAN   :: 0x00FFFF;
    BLUE   :: 0x0066E6;
    YELLOW :: 0xE6E600;
    ORANGE :: 0xFF9900;
    PINK   :: 0xFF66B2;
    BROWN  :: 0x66664C;
}

ColorToVector4 :: (color: Color) -> Vector4 {
    rgb := HexToRGB(cast(int) color);
    return ToVector(Vector4Int.{ rgb.x, rgb.y, rgb.z, 255 }) / 255;
}

PushColor :: (color: Vector4) #expand {
    new_context := context;
    new_context.drawing_state.color = color;
    `push_context,defer_pop new_context;
}

PushColor :: (r : float, g : float, b : float, a := 1.0) #expand {
    new_context := context;
    new_context.drawing_state.color = { r, g, b, a };
    `push_context,defer_pop new_context;
}

PushColor :: (color: Color) #expand {
    new_context := context;
    new_context.drawing_state.color = ColorToVector4(color);
    `push_context,defer_pop new_context;
}

PushColor :: (color: Vector4Int) #expand {
    new_context := context;
    new_context.drawing_state.color = ToVector(color) / 255.0;
    `push_context,defer_pop new_context;
}

PushRGB :: (color: int) #expand {
    assert(color <= 0xFFFFFF);
    new_context := context;
    rgb := HexToRGB(cast(int) color);
    new_context.drawing_state.color = ToVector(Vector4Int.{ rgb.x, rgb.y, rgb.z, 255 }) / 255;
    `push_context,defer_pop new_context;
}

PushRGBA :: (color: int) #expand {
    new_context := context;
    rgba := HexToRGBA(cast(int) color);
    new_context.drawing_state.color = ToVector(rgba) / 255;
    `push_context,defer_pop new_context;
}

PushAlpha :: (alpha: float) #expand {
    new_context := context;
    new_context.drawing_state.color.w = alpha;
    `push_context,defer_pop new_context;
}

PushWidth :: (width: float) #expand {
    new_context := context;
    new_context.drawing_state.width = width;
    `push_context,defer_pop new_context;
}

PushMode :: (mode: Drawing_Mode) #expand {
    new_context := context;
    new_context.drawing_state.mode = mode;
    `push_context,defer_pop new_context;
}

PushAlignment :: (align: Drawing_Alignment) #expand {
    new_context := context;
    new_context.drawing_state.align = align;
    `push_context,defer_pop new_context;
}

PushFlip :: (flip: Flip_Flag) #expand {
    new_context := context;
    new_context.drawing_state.flip = flip;
    `push_context,defer_pop new_context;
}

PushTransform :: (transform: Matrix4) #expand {
    new_context := context;
    new_context.drawing_state.transform *= transform;
    `push_context,defer_pop new_context;
}

PushTransform :: (transform: Transform) #expand {
    new_context := context;
    new_context.drawing_state.transform *= ToMatrix(transform);
    `push_context,defer_pop new_context;
}

PushTransform :: (translation: Vector2, rotation: float, scaling: $T/Scaling_Type) #expand {
    transform : Transform;
    transform.translation = translation;
    transform.rotation    = rotation;
    transform.scaling     = #ifx T == float then .{ scaling, scaling } else scaling;

    new_context := context;
    new_context.drawing_state.transform *= ToMatrix(transform);
    `push_context,defer_pop new_context;
}

PushTranslation :: (translation: Vector2) #expand {
    new_context := context;
    new_context.drawing_state.transform *= TranslationMatrix(translation);
    `push_context,defer_pop new_context;
}

PushTranslation :: (x: float, y: float) #expand {
    new_context := context;
    new_context.drawing_state.transform *= TranslationMatrix(Vector2.{ x, y });
    `push_context,defer_pop new_context;
}

PushRotation :: (rotation: float) #expand {
    new_context := context;
    new_context.drawing_state.transform *= RotationMatrix(rotation);
    `push_context,defer_pop new_context;
}

PushScale :: (scaling: $T/Scaling_Type) #expand {
    new_context := context;
    new_context.drawing_state.transform *= ScalingMatrix(scaling);
    `push_context,defer_pop new_context;
}

PushCamera :: (using camera: Camera) #expand {
    new_context := context;
    new_context.drawing_state.transform *= TranslationMatrix(focus);
    new_context.drawing_state.transform *= ScalingMatrix(scaling);
    new_context.drawing_state.transform *= RotationMatrix(rotation);
    new_context.drawing_state.transform *= TranslationMatrix(-translation);
    `push_context,defer_pop new_context;
}

DrawVertices :: (vertices: [] Vector2) {
    using context.drawing_state;

    Simp.set_shader_for_color(enable_blend = true);

    if mode == {
        case .FILL;
            for i : 1..vertices.count - 2 {
                j := (i+1) % vertices.count;
                a := TransformPoint(vertices[0], transform);
                b := TransformPoint(vertices[i], transform);
                c := TransformPoint(vertices[j], transform);
                Simp.immediate_triangle({ a.x, a.y, 0 }, { b.x, b.y, 0 }, { c.x, c.y, 0 }, color, color, color);
            }

        case .LINE;
            if vertices.count == 2 {
                a := TransformPoint(vertices[0], transform);
                b := TransformPoint(vertices[1], transform);
                v := normalize(b - a);
                half_width := width * 0.5;
                n := Vector2.{ v.y, -v.x } * half_width;
                Simp.immediate_quad(a - n, b - n, b + n, a + n, color);
            } else {
                get_miter_points :: (i: int) -> (left: Vector2, right: Vector2) #expand {
                    prev := vertices[(i - 1 + vertices.count) % vertices.count];
                    curr := vertices[i];
                    next := vertices[(i + 1) % vertices.count];

                    v1 := normalize(curr - prev);
                    v2 := normalize(next - curr);

                    n1 := Vector2.{ -v1.y, v1.x };
                    n2 := Vector2.{ -v2.y, v2.x };

                    miter := normalize(n1 + n2);
                    d := dot(miter, n1);

                    half_width := width * 0.5;

                    miter_dist := half_width;
                    if abs(d) > 0.0001 miter_dist = half_width / d;
                    miter_dist = min(miter_dist, half_width * 5.0);

                    return curr + miter * miter_dist, curr - miter * miter_dist;
                }

                curr_l, curr_r := get_miter_points(0);

                for 0..vertices.count - 1 {
                    next_l, next_r := get_miter_points((it+1) % vertices.count);

                    a := TransformPoint(curr_l, transform);
                    b := TransformPoint(next_l, transform);
                    c := TransformPoint(next_r, transform);
                    d := TransformPoint(curr_r, transform);

                    Simp.immediate_quad(a, b, c, d, color);

                    curr_l, curr_r = next_l, next_r;
                }
            }
    }
}

DrawPoint :: (using point: Vector2) {
    PushMode(.FILL);
    DrawVertices(Points(MakeRectangleFromCenter(point, context.drawing_state.width)));
}

DrawSegment :: (using segment: Segment) {
    PushMode(.LINE);
    DrawVertices(Points(segment));
}

DrawRectangle :: (using rectangle: Rectangle) {
    DrawVertices(Points(rectangle));
}

DrawCircle :: (using circle: Circle) {
    DrawVertices(Points(circle, nb_of_points = 50));
}

DrawPolygon :: DrawVertices;

DrawPolygon :: (using polygon: Polygon) {
    DrawVertices(points);
}

DrawRoundedSegment :: (using rs: Rounded_Segment) {
    DrawRoundedPolygon({ { Points(segment) }, r });
}

DrawRoundedRectangle :: (using rr: Rounded_Rectangle) {
    DrawRoundedPolygon({ { Points(rectangle) }, r });
}

DrawRoundedPolygon :: (using rp: Rounded_Polygon) {
    nb_of_points :: 60;
    rounded_points: [nb_of_points] Vector2;

    points_per_corner := nb_of_points / points.count;

    if points.count == 2 {
        using segment := Segment.{ points[0], points[1] };
        dir := Direction(segment);

        for * rounded_points {
            angle := ifx it_index < points_per_corner then 0.0 else PI;

            t     := (it_index % points_per_corner) / cast(float)(points_per_corner - 1);
            theta := angle + (t * PI) - (PI / 2);

            c := cos(theta);
            s := sin(theta);

            center := ifx it_index < points_per_corner then b else a;
            pos    := Vector2.{ c * dir.x - s * dir.y, c * dir.y + s * dir.x };
            it.* = center + pos * r;
        }
    } else {
        rest := nb_of_points % points.count;

        point_index := 0;

        for i: 0..points.count - 1 {
            prev := points[(i - 1 + points.count) % points.count];
            curr := points[i];
            next := points[(i + 1) % points.count];

            pa := curr + Normal(Segment.{ prev, curr }) * r;
            pb := curr + Normal(Segment.{ curr, next }) * r;

            angle_a := atan2(pa.y - curr.y, pa.x - curr.x);
            angle_b := atan2(pb.y - curr.y, pb.x - curr.x);

            angle := angle_b - angle_a;
            if angle >  PI angle -= TAU;
            if angle < -PI angle += TAU;

            ppc := points_per_corner;
            if rest > 0 {
                ppc  += 1;
                rest -= 1;
            }

            for j : 0..ppc - 1 {
                t     := j / cast(float)(ppc - 1);
                theta := angle_a + t * angle;

                rounded_points[point_index] = curr + { cos(theta), sin(theta) } * r;
                point_index += 1;
            }
        }
    }

    DrawVertices(rounded_points);
}

DrawEllipse :: (using ellipse: Ellipse) {
    nb_of_points :: 50;
    THETA :: TAU / nb_of_points;
    vertices : [nb_of_points] Vector2;
    for * vertices it.* = Vector2.{ x, y } + Vector2.{ cos(THETA * it_index) * w, sin(THETA * it_index) * h };
    DrawPolygon({ vertices });
}

LoadTexture :: (path: string) -> Texture {
    texture : Texture;
    loaded := Simp.texture_load_from_file(*texture, path);
    assert(loaded);
    return texture;
}

Size :: (using texture: Texture) -> Vector2 {
    return { xx width, xx height };
}

DrawTexture :: (texture: Texture) {
    using context.drawing_state;

    x, y, w, h: float;

    w = xx texture.width;
    h = xx texture.height;

    if      align == .TR || align == .CR || align == .BR  x -= w;
    else if align == .TC || align == .CC || align == .BC  x -= w/2;

    if      align == .BL || align == .BC || align == .BR  y -= h;
    else if align == .CL || align == .CC || align == .CR  y -= h/2;

    l, t, r, b := x, y, x + w, y + h;

    if flip & .HORIZONTAL swap(*l, *r);
    if flip & .VERTICAL   swap(*t, *b);

    tl := TransformPoint({ l, t }, transform);
    tr := TransformPoint({ r, t }, transform);
    br := TransformPoint({ r, b }, transform);
    bl := TransformPoint({ l, b }, transform);

    Simp.set_shader_for_images(*texture);
    GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
    GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
    Simp.immediate_quad(tl, tr, br, bl, color);
}

DrawTexture :: (using texture: Texture, position: Vector2, rotation : float, scaling: $T/Scaling_Type) {
    PushTransform(position, rotation, scaling);
    DrawTexture(texture);
}

DrawTexture :: (using texture: Texture, using rectangle: Rectangle) {
    PushTransform(Center(rectangle), 0.0, { w / width, h / height });
    PushAlignment(.CENTER);
    DrawTexture(texture);
}

LoadFont :: (path: string, size: int) -> *Font {
    font := Simp.get_font_at_size(".", path, size);
    assert(font != null);
    return font;
}

Size :: (using font: *Font, text: string) -> Vector2 {
    return { xx Simp.prepare_text(font, text), character_height / 2.0 };
}

DrawText :: (using font: *Font, text: string, args: .. Any) {
    using context.drawing_state;

    w : float = xx Simp.prepare_text(font, tprint(text, ..args));
    h : float = character_height / 2.0;

    Simp.generate_quads_for_prepared_text(font, 0, 0, xx 0);

    for * quad : font.current_quads {
        using quad;

        if flip & .HORIZONTAL {
            p0.x, p1.x, p2.x, p3.x *= -1;
            p0.x, p1.x, p2.x, p3.x += w;
        }

        if flip & .VERTICAL {
            p0.y, p1.y, p2.y, p3.y *= -1;
            p0.y, p1.y, p2.y, p3.y -= h;
        }

        if      align == .TR || align == .CR || align == .BR  p0.x, p1.x, p2.x, p3.x -= w;
        else if align == .TC || align == .CC || align == .BC  p0.x, p1.x, p2.x, p3.x -= w/2;

        if      align == .TL || align == .TC || align == .TR  p0.y, p1.y, p2.y, p3.y += h;
        else if align == .CL || align == .CC || align == .CR  p0.y, p1.y, p2.y, p3.y += h/2;

        TransformPoint(*p0, transform);
        TransformPoint(*p1, transform);
        TransformPoint(*p2, transform);
        TransformPoint(*p3, transform);
    }

    Simp.draw_generated_quads(font, color);
}

Animation :: struct {
    frames  : [..] Frame;
    index   : int;
    elapsed := 0.0;
    playing := true;
    looping := true;
}

Frame :: struct {
    texture  : *Texture;
    duration : float;
}

Update :: (using animation: *Animation, dt: float) {
    if playing  elapsed += dt;

    if elapsed >= frames[index].duration {
        elapsed = 0.0;

        if index < frames.count - 1 {
            index += 1;
        } else if looping {
            index = 0;
        } else {
            playing = false;
        }
    }
}

DrawAnimation :: (using animation: Animation) {
    DrawTexture(frames[index].texture);
}

DrawAnimation :: (using animation: Animation, position: Vector2, rotation := 0.0, scaling := 1.0) {
    DrawTexture(frames[index].texture, position, rotation, scaling);
}

DrawAnimation :: (using animation: Animation, using rectangle: Rectangle) {
    DrawTexture(frames[index].texture, rectangle);
}

Particle_Emitter :: struct {
    texture  : *Texture;

    lifetime  := -1.0;
    elapsed   :=  0.0;
    remainder :=  0.0;

    producing := true;
    particles_per_second := 10;

    production_zone : union kind : Type = Vector2 {
        point     : Vector2;
        segment   : Segment;
        rectangle : Rectangle;
        circle    : Circle;
    }

    particles : [..] Particle;

    gravity : Vector2;

    fadein\_period := 0.1;
    fadeout_period := 0.1;

    min_speed    := 50.0;
    max_speed    := 50.0;

    min_scale    := 1.0;
    max_scale    := 1.0;

    min_drag     := 0.0;
    max_drag     := 0.0;

    min_lifetime := 1.0;
    max_lifetime := 1.0;

    min_theta    := 0.0;
    max_theta    := TAU;

    min_color    := Vector4.{ 1, 1, 1, 1 };
    max_color    := Vector4.{ 1, 1, 1, 1 };
}

Particle :: struct {
    position : Vector2;
    velocity : Vector2;
    color    : Vector4;
    size     : Vector2;
    drag     : float;
    lifetime : float;
    elapsed  := 0.0;
}

Deinit :: (using emitter: *Particle_Emitter) {
    array_free(particles);
}

Update :: (using emitter: *Particle_Emitter, dt: float) {
    Update :: (using particle: *Particle, dt: float) #expand {
        velocity -= emitter.gravity * dt;
        velocity *= 1 - drag;
        position += velocity * dt;
        elapsed  += dt;
    }

    for * particles {
        Update(it, dt);
        if it.elapsed > it.lifetime remove it;
    }

    if lifetime > 0 {
        lifetime -= dt;
        if lifetime < 0 producing = false;
    }

    if !producing return;

    elapsed   += dt;
    remainder += dt;

    seconds_per_particle := 1.0 / particles_per_second;
    while remainder > seconds_per_particle {
        remainder -= seconds_per_particle;
        Update(SpawnOne(emitter), remainder);
    }
}

SpawnOne :: (using emitter: *Particle_Emitter) -> *Particle {
    position: Vector2;

    using production_zone;
    if kind == {
        case Vector2;   position = point;
        case Segment;   position = RandomPoint(segment);
        case Rectangle; position = RandomPoint(rectangle);
        case Circle;    position = RandomPoint(circle);
    }

    return SpawnOneAt(emitter, position);
}

SpawnOneAt :: (using emitter: *Particle_Emitter, position: Vector2) -> *Particle {
    particle := array_add(*particles);

    particle.position = position;

    size := Vector2.{ xx texture.width, xx texture.height };
    particle.size = size * RandomFloat(min_scale, max_scale);

    theta := RandomFloat(min_theta, max_theta);
    speed := RandomFloat(min_speed, max_speed);
    particle.velocity = VectorFromPolar(theta, speed);

    particle.drag     = RandomFloat(min_drag, max_drag);
    particle.lifetime = RandomFloat(min_lifetime, max_lifetime);
    particle.color    = lerp(min_color, max_color, RandomFloat(0, 1));

    return particle;
}

DrawEmitter :: (using emitter: Particle_Emitter) {
    Simp.set_shader_for_images(texture);
    GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
    GL.glTexParameterf(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

    for < particles {
        alpha := 1.0;

        if fadein_period  > it.elapsed {
            alpha = it.elapsed / fadein_period;
        }

        if fadeout_period > it.lifetime - it.elapsed  {
            alpha = (it.lifetime - it.elapsed) / fadeout_period;
        }

        Clamp(*alpha, 0.0, 1.0);

        color := it.color;
        color.w *= alpha;

        l := it.position.x - it.size.x * .5;
        t := it.position.y - it.size.y * .5;
        r := it.position.x + it.size.x * .5;
        b := it.position.y + it.size.y * .5;

        tl := TransformPoint({ l, t }, context.drawing_state.transform);
        tr := TransformPoint({ r, t }, context.drawing_state.transform);
        br := TransformPoint({ r, b }, context.drawing_state.transform);
        bl := TransformPoint({ l, b }, context.drawing_state.transform);

        Simp.immediate_quad(tl, tr, br, bl, color);
    }
}