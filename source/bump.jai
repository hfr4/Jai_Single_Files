ApplicationTitle :: "Bump";
ApplicationWidth  :: 1000;
ApplicationHeight :: 1000;

ApplicationInit :: () {
	SetFocus(*camera, ApplicationCenter());
}

ApplicationReset :: () {
	camera.translation = { 0, 0 };

	a = { -300, -300, 50, 100  };
	b = {  200,  200, 300, 150 };
}

ApplicationEvents :: () {
	if Down(.MOUSE_BUTTON_LEFT) {
		mp := MousePositionOnCamera(camera);
		SetTL(*a, mp);
	}

	if Down(.MOUSE_BUTTON_RIGHT) {
		mp := MousePositionOnCamera(camera);
		SetCenter(*b, mp);
	}
}

ApplicationUpdate :: (dt: float) {

}

ApplicationRender :: () {
	PushCamera(camera);

	{
		PushWidth(5);
		DrawPoint({ 0, 0 });
	}

	PushWidth(2.0);
	PushMode(.LINE);

	PushColor(.RED);
	DrawRectangle(a);

	PushColor(.GREEN);
	DrawRectangle(b);

	segment := Segment.{ TL(a), MousePositionOnCamera(camera) };

	PushColor(.WHITE);
	DrawSegment(segment);
	c := a;
	SetTL(*c, segment.b);


	{
		ok, intersection := DetectIntersection(b, segment);

		if ok {
			PushMode(.FILL);
			PushColor(.GREEN);
			PushAlpha(.5);
			DrawRectangle({ b.x, b.y, b.w, b.h });

			PushColor(.WHITE);
			DrawSegment(segment);

			pi := segment.a + Length(segment) * intersection.entry_time * Direction(segment);

			PushColor(.YELLOW);
			PushWidth(5);
			DrawPoint(pi);

			pj := segment.a + Length(segment) * intersection.exit_time * Direction(segment);

			PushColor(.RED);
			PushWidth(5);
			DrawPoint(pj);

			si := MakeSegmentFromVector(pi, intersection.entry_normal * 30.0);
			PushColor(.YELLOW);
			PushWidth(2);
			DrawSegment(si);

			sj := MakeSegmentFromVector(pj, intersection.exit_normal * 30.0);
			PushColor(.RED);
			PushWidth(2);
			DrawSegment(sj);

		} else {
			PushColor(.WHITE);
			DrawSegment(segment);
		}
	}

	if 0 {
		ok, collision := DetectCollision(a, b, segment.b);

		if ok {
			{
				SetTL(*c, collision.touch);
				PushWidth(2.0);
				PushColor(.RED);
				DrawRectangle(c);
			}

			if collision.overlaps {
				PushColor(.YELLOW);
				PushAlpha(.3);
				PushMode(.FILL);
				DrawRectangle(b);
			} else {
				PushColor(.GREEN);
				PushAlpha(.3);
				PushMode(.FILL);
				DrawRectangle(b);
			}


			{
				PushWidth(15);
				DrawPoint(collision.touch);
			}

			{
				PushWidth(3);
				DrawSegment(MakeSegmentFromVector(Center(c), collision.normal * 30.0));
			}

			{
				PushWidth(15);
				p0 := TL(a);

				dir := collision.vector;
				PushColor(.YELLOW);
				DrawPoint(p0 + dir * collision.time);
			}

		}
		{
			d := MinkowskiDif(a, b);

			PushColor(.PINK);
			DrawRectangle(d);
		}
	}
}

camera : Camera;

a, b : Rectangle;

Bump_Collision :: struct {
	overlaps : bool;
	time     : float;
	vector   : Vector2;
	normal   : Vector2;
	touch    : Vector2;
}

Bump_Intersection :: struct {
	entry_time   : float;
	entry_normal : Vector2;
	exit_time    : float;
	exit_normal  : Vector2;
}

DetectIntersection :: (rectangle: Rectangle, segment: Segment, a_is_ray : bool = false, b_is_ray : bool = false) -> bool, Bump_Intersection {
    entry_time := ifx a_is_ray then -FLOAT32_MAX else 0.0;
    exit_time  := ifx b_is_ray then  FLOAT32_MAX else 1.0;

    entry_normal, exit_normal : Vector2;

	v := Vector(segment);

    for side : 1..4 {
		normal : Vector2;
    	p, q : float;

        if side == {
        	case 1; normal, p, q = { -1,  0 }, -v.x, segment.a.x - L(rectangle);
        	case 2; normal, p, q = {  0, -1 }, -v.y, segment.a.y - T(rectangle);
        	case 3; normal, p, q = { +1,  0 },  v.x, R(rectangle) - segment.a.x;
        	case 4; normal, p, q = {  0, +1 },  v.y, B(rectangle) - segment.a.y;
        }

        if p == 0.0 {
            if q <= 0.0 return false, {};
        } else {
            time := q / p;
            if p < 0.0 {
                if time > exit_time  return false, {};
                if time > entry_time entry_time, entry_normal = time, normal;
            } else {
                if time < entry_time return false, {};
                if time < exit_time  exit_time, exit_normal = time, normal;
            }
        }
    }

    return true, {
		entry_time,
		entry_normal,
		exit_time,
		exit_normal,
	};
}

DetectCollision :: (rect: Rectangle, other: Rectangle, rect_target: Vector2) -> bool, Bump_Collision {
	dif := MinkowskiDif(rect, other);

	vector := rect_target - TL(rect);

	time     : float;
	normal   : Vector2;
	overlaps := false;

	if Colliding(dif, Vector2.{ 0, 0 }) {
		nx := Closest(0, L(dif), R(dif));
		ny := Closest(0, T(dif), B(dif));

		wi := min(rect.w, abs(nx));
		hi := min(rect.h, abs(ny));

		time     = -wi * hi;
		overlaps = true;
	} else {
		ok, intersection := DetectIntersection(dif, MakeSegmentFromVector(vector), a_is_ray = true, b_is_ray = true);
		if !ok return false, {};

		using intersection;

		EPSILON :: 1.0e-10;
		if !(entry_time < 1 && (abs(entry_time - exit_time) >= EPSILON) && (0 < entry_time + EPSILON || (entry_time == 0 && exit_time > 0))) return false, {};

		time     = entry_time;
		normal   = entry_normal;
		overlaps = false;
	}

	touch : Vector2;

	if overlaps {
		nx := Closest(0, R(dif), L(dif));
		ny := Closest(0, T(dif), B(dif));
		if abs(nx) < abs(ny) { ny = 0; } else { nx = 0; }

		normal = { Sign(nx), Sign(ny) };
		touch  = TL(rect) + { nx, ny };
	} else {
		touch = TL(rect) + vector * time;
	}

	return true, {
		overlaps = overlaps,
		time     = time,
		vector   = vector,
		normal   = normal,
		touch    = touch,
	};
}
