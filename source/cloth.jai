ApplicationTitle  :: "Verlet";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    Init(*my_cloth, 100, 100, 10, 10, 30.0);
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();
}

ApplicationUpdate :: (dt: float) {
    Update(*my_cloth, dt);
}

ApplicationRender :: () {
    Draw(*my_cloth);
}

my_cloth: Cloth;

Cloth :: struct {
	gravity    : Vector2 = { 0.0, 500 };
	drag       : float   = 0.01;
	elasticity : float   = 1.0;
	points     : [..] *Point;
	sticks     : [..] *Stick;
}

Init :: (using cloth: *Cloth, x: float, y: float, rows: int, cols: int, spacing: float) {
    for col: 0..cols - 1 {
        for row: 0..rows - 1 {

            point := New(Point);
            Init(point, x + row * spacing, y + col * spacing);

            array_add(*points, point);

            point_index := points.count - 1;

            if row != 0 {
                r_point := point;
                l_point := points[point_index - 1];

                stick := New(Stick);
                Init(stick, r_point, l_point, spacing);
                array_add(*sticks, stick);

                l_point.sticks[0] = stick;
                r_point.sticks[0] = stick;
            }

            if col != 0 {
                b_point := point;
                t_point := points[point_index - rows];

                stick := New(Stick);
                Init(stick, b_point, t_point, spacing);

                array_add(*sticks, stick);

                b_point.sticks[1] = stick;
                t_point.sticks[1] = stick;
            }

            if col == 0  {
                point.is_pinned = true;
            }
        }
    }
}

Update :: (using cloth: *Cloth, dt: float) {
	for sticks Update(it);

    for points {
        CURSOR_SIZE :: 20.0;

        it.is_selected = distance(it.position, MousePositionOnApplication()) < CURSOR_SIZE;

        if it.sticks[0] then it.sticks[0].is_selected = it.is_selected;
        if it.sticks[1] then it.sticks[1].is_selected = it.is_selected;

        if Down(.MOUSE_BUTTON_RIGHT) && it.is_selected {
            if it.sticks[0] then it.sticks[0].is_active = false;
            if it.sticks[1] then it.sticks[1].is_active = false;
        }

	    Update(it, dt, drag, gravity, elasticity);

        Clamp(*it.position.x    , 0, ApplicationRectangle().w);
        Clamp(*it.old_position.x, 0, ApplicationRectangle().w);
        Clamp(*it.position.y    , 0, ApplicationRectangle().h);
        Clamp(*it.old_position.y, 0, ApplicationRectangle().h);
    }
}

Draw :: (using cloth: *Cloth) {
	for sticks Draw(it);
	for points Draw(it);
}

Stick :: struct {
	points      : [2] *Point;
	length      : float;
	is_active   : bool = true;
	is_selected : bool = false;
}

Init :: (stick: *Stick, point0: *Point, point1: *Point, length: float) {
    stick.points[0] = point0;
    stick.points[1] = point1;
    stick.length    = length;
}

Update :: (using stick: *Stick) {
	if !is_active return;

	points_vector   := points[0].position - points[1].position;
	points_distance := distance(points[0].position, points[1].position);
	diff_factor     := (length - points_distance) / points_distance;
	offset          := points_vector * diff_factor * 0.5;

	if !points[0].is_pinned  points[0].position += offset;
	if !points[1].is_pinned  points[1].position -= offset;
}

Draw :: (using stick: *Stick) {
	if !is_active return;

	COLOR_WHEN_NOT_SELECTED :: Vector4.{ 1.0, 0.0, 0.4, 1.0 };
	COLOR_WHEN_SELECTED     :: Vector4.{ 1.0, 0.8, 0.0, 1.0 };

    segment_vector := normalize(points[1].position - points[0].position);
    perpendicular  := Vector2.{ segment_vector.y, -segment_vector.x };
    normal         := perpendicular * .5;

    quad := Vector2.[
        points[0].position - normal,
        points[0].position + normal,
        points[1].position + normal,
        points[1].position - normal,
    ];

    color := ifx is_selected then COLOR_WHEN_SELECTED else COLOR_WHEN_NOT_SELECTED;
    PushColor(color);
    DrawSegment({ points[0].position, points[1].position });
}

Point :: struct {
	position         : Vector2;
	old_position     : Vector2;
	initial_position : Vector2;
	is_pinned        : bool;
	is_selected      : bool;
    sticks           : [2] *Stick;
}

Init :: (using point: *Point, x: float, y: float) {
    position         = { x, y };
    old_position     = { x, y };
    initial_position = { x, y };
}

Update :: (using point: *Point, dt: float, drag: float, acceleration: Vector2, elasticity: float) {
	if is_pinned {
		position = initial_position;
	} else {
        new_position := position + (position - old_position) * (1.0 - drag) + acceleration * (1.0 - drag) * dt * dt;

        old_position = position;
        position     = new_position;
    }
}

Draw :: (using point: Point) {
    COLOR_WHEN_PINNED     :: Vector4.{ 0, 1, 1, 1 };
    COLOR_WHEN_NOT_PINNED :: Vector4.{ 1, 1, 1, 1 };

    if is_pinned {
        PushColor(COLOR_WHEN_PINNED);
        PushWidth(5);
        DrawPoint(position);
    } else {
        PushColor(COLOR_WHEN_NOT_PINNED);
        PushWidth(3);
        DrawPoint(position);
    }
}