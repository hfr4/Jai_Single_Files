ApplicationTitle  :: "3D CPU";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_cam = {
		position  = { 0, 0,-2 },
		direction = { 0, 0, 1 },
		up        = { 0, 1, 0 },
		near      = .1,
		far       = 1000,
		fov       = PI/3,
		ar        = AspectRatio(),
	};
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Down(.MOUSE_BUTTON_MIDDLE) {
        Move(*my_cam, MouseDeltaOnApplication(), .002);
    }

    if Down("Q")    MoveNoclip(*my_cam, .LEFT  , .008);
    if Down("D")    MoveNoclip(*my_cam, .RIGHT , .008);
    if Down("Z")    MoveNoclip(*my_cam, .TOWARD, .008);
    if Down("S")    MoveNoclip(*my_cam, .BACK  , .008);
    if Down(.SHIFT) MoveNoclip(*my_cam, .UP    , .008);
    if Down(.CTRL)  MoveNoclip(*my_cam, .DOWN  , .008);
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
    DrawTriangles3D(ProjectionMatrix(my_cam) * ViewMatrix(my_cam), NearPlanePosition(my_cam), my_cam.direction, my_triangles);
}

my_triangles :: #run SphereTriangle();
my_cam : Camera3D;

Triangle3D :: [3] Vector3;
Segment3D  :: [2] Vector3;

DrawPoint3D :: (pv_matrix: Matrix4, near: Vector3, direction: Vector3, point: Vector3) {
	ok, screen_coord := WorldToScreen(pv_matrix, near, direction, point);
    if !ok return;

    PushWidth(10);
	DrawPoint(screen_coord.xy);
}

DrawSegment3D :: (pv_matrix: Matrix4, near: Vector3, direction: Vector3, segment: Segment3D) {
	is_p0_infront, point0 := WorldToScreen(pv_matrix, near, direction, segment[0]);
	is_p1_infront, point1 := WorldToScreen(pv_matrix, near, direction, segment[1]);
	if !is_p0_infront && !is_p1_infront return;

	col_ok, col := SegmentPlaneCollision(segment[0], segment[1], near, direction);

	if col_ok {
		if !is_p0_infront {
            ok:, point0 = WorldToScreen(pv_matrix, near - direction, direction, col);
            if !ok return;
        }
		if !is_p1_infront {
            ok:, point1 = WorldToScreen(pv_matrix, near - direction, direction, col);
            if !ok return;
        }
	}

    PushWidth(2);
	DrawSegment({ point0.xy, point1.xy });
}

DrawTriangle3D :: (pv_matrix: Matrix4, near: Vector3, direction: Vector3, triangle: Triangle3D) {
	points: [4] Vector3;

	is_p0_infront: bool;
	is_p1_infront: bool;
	is_p2_infront: bool;

	is_p0_infront, points[0] = WorldToScreen(pv_matrix, near, direction, triangle[0]);
	is_p1_infront, points[1] = WorldToScreen(pv_matrix, near, direction, triangle[1]);
	is_p2_infront, points[2] = WorldToScreen(pv_matrix, near, direction, triangle[2]);

	draw_points_count := 3;
	is_triangle_clipped: bool;

	infront_count: int;
	if is_p0_infront infront_count += 1;
	if is_p1_infront infront_count += 1;
	if is_p2_infront infront_count += 1;

	if infront_count == 0 return;

	if infront_count == 1 {
		infront, behind1, behind2: Vector3;
		if is_p0_infront infront, behind1, behind2 = triangle[0], triangle[1], triangle[2];
		if is_p1_infront infront, behind1, behind2 = triangle[1], triangle[2], triangle[0];
		if is_p2_infront infront, behind1, behind2 = triangle[2], triangle[0], triangle[1];

		col_ok0, col0 := SegmentPlaneCollision(behind1, infront, near, direction);
		col_ok1, col1 := SegmentPlaneCollision(behind2, infront, near, direction);
        if !col_ok0 || !col_ok1 return;

		ok0:, points[0] = WorldToScreen(pv_matrix, near - direction, direction, col0);
		ok1:, points[1] = WorldToScreen(pv_matrix, near - direction, direction, col1);
		ok2:, points[2] = WorldToScreen(pv_matrix, near - direction, direction, infront);
        if !ok0 || !ok1 || !ok2 return;

		is_triangle_clipped = true;
	} else if infront_count == 2 {
		behind, infront1, infront2: Vector3;
		if !is_p0_infront behind, infront1, infront2 = triangle[0], triangle[1], triangle[2];
		if !is_p1_infront behind, infront1, infront2 = triangle[1], triangle[2], triangle[0];
		if !is_p2_infront behind, infront1, infront2 = triangle[2], triangle[0], triangle[1];

		col_ok0, col0 := SegmentPlaneCollision(behind, infront1, near, direction);
		col_ok1, col1 := SegmentPlaneCollision(behind, infront2, near, direction);
        if !col_ok0 || !col_ok1 return;

		ok0:, points[0] = WorldToScreen(pv_matrix, near - direction, direction, col0);
		ok1:, points[1] = WorldToScreen(pv_matrix, near - direction, direction, infront1);
		ok2:, points[2] = WorldToScreen(pv_matrix, near - direction, direction, infront2);
		ok3:, points[3] = WorldToScreen(pv_matrix, near - direction, direction, col1);
        if !ok0 || !ok1 || !ok2 || !ok3 return;

		draw_points_count   = 4;
		is_triangle_clipped = true;
	}

    PushWidth(2);
	if draw_points_count == 3 {
		if !is_triangle_clipped DrawSegment({ points[0].xy, points[1].xy });
		DrawSegment({ points[1].xy, points[2].xy });
		DrawSegment({ points[2].xy, points[0].xy });
	} else if draw_points_count == 4 {
		DrawSegment({ points[0].xy, points[1].xy });
		DrawSegment({ points[1].xy, points[2].xy });
		DrawSegment({ points[2].xy, points[3].xy });
	}
}

DrawTriangles3D :: (pv_matrix: Matrix4, near: Vector3, direction: Vector3, triangles: [] Triangle3D) {
    for triangles DrawTriangle3D(pv_matrix, near, direction, it);
}

WorldToScreen :: (pv_matrix: Matrix4, near: Vector3, direction: Vector3, point: Vector3) -> bool, Vector3 {
	is_point_infront := (dot(point - near, direction) > 0);
	if !is_point_infront return false, {};
	cc  := pv_matrix * { point.x, point.y, point.z, 1 };
	ndc := cc.xyz / cc.w;
	sc  := (ndc.xy + { 1, 1 }) * HalfSize(ApplicationRectangle());
	return true, { sc.x, sc.y, ndc.z };
}

SegmentPlaneCollision :: (s0: Vector3, s1: Vector3, plane_pos: Vector3, plane_normal: Vector3) -> bool, Vector3 {
	dir := normalize(s1 - s0);
	d1 := dot(plane_pos, -plane_normal);
	d2 := dot(s0, plane_normal);
	d3 := dot(dir, plane_normal);
	dist := -(d1 + d2) / d3;
	if dist < .001 || dist > length(s1 - s0) return false, {};
	return true, s0 + (dir * dist);
}

Camera3D :: struct {
	position  : Vector3;
	direction : Vector3;
	up        : Vector3;
	near      : float;
	far       : float;
	fov       : float;
	ar        : float;
}

Yaw :: (using camera: Camera3D) -> float {
	return -atan2(direction.z, direction.x) + PI/2;
}

Pitch :: (using camera: Camera3D) -> float {
	return -atan2(direction.y, sqrt(direction.x*direction.x + direction.z*direction.z));
}

ProjectionMatrix :: (using camera: Camera3D) -> Matrix4 {
    x :=  1 / (ar * tan(fov / 2));
    y :=  1 / (tan(fov / 2));
    z := -1 * ((far + near) / (far - near));
    w := -1 * (( 2 * far * near) / (far - near));

    return {
        x, 0, 0 , 0,
        0, y, 0 , 0,
        0, 0, z , w,
        0, 0, -1, 0,
    };
}

ViewMatrix :: (using camera: Camera3D) -> Matrix4 {
    z := -normalize(direction);
    x := -normalize(cross(up, z));
    y := cross(z, x);

    return {
        x.x, x.y, x.z, -1 * dot(x, position),
        y.x, y.y, y.z, -1 * dot(y, position),
        z.x, z.y, z.z, -1 * dot(z, position),
        0  , 0  , 0  , 1,
    };
}

NearPlanePosition :: (using camera: Camera3D) -> Vector3 {
	return position + (direction * near);
}

LookAt :: (using camera: *Camera3D, target: Vector3) {
	dir := target - position;
	dir.x = max(dir.x, .001); // Prevent visual bug when looking straight up/down
	yaw   := -atan2(dir.z, dir.x) + PI / 2.0;
	pitch := -atan2(dir.y, sqrt(dir.x*dir.x + dir.z*dir.z));
    Look(camera, yaw, pitch);
}

Look :: (using camera: *Camera3D, yaw: float, pitch: float) {
	cos_pitch := max(abs(cos(pitch)), .001); // Prevent visual bug when looking straight up/down
	direction = {
		sin(yaw)   * cos_pitch,
		sin(pitch) * -1,
		cos(yaw)   * cos_pitch,
	};
}

Move :: (using camera: *Camera3D, delta: Vector2, sensitivity: float) {
	yaw   := Yaw(camera)   + delta.x * sensitivity;
	pitch := Pitch(camera) + delta.y * sensitivity;
	Clamp(*pitch, -PI/2, PI/2);
	Look(camera, yaw, pitch);
}

Noclip_Direction :: enum {
    RIGHT_ABS; LEFT_ABS; FORTH_ABS; BACK_ABS;
    UP; DOWN; LEFT; RIGHT;
    FORTH; BACK; AWAY_FROM; TOWARD;
}

MoveNoclip :: (using camera: *Camera3D, noclip_direction: Noclip_Direction, speed: float) {
	dx, dy, dz: float;

	if noclip_direction == {
	    // Move camera's absolute position
        case .RIGHT_ABS;  position.x += speed;
        case .LEFT_ABS;   position.x -= speed;
        case .FORTH_ABS;  position.z += speed;
        case .BACK_ABS;   position.z -= speed;
        case .UP;         position.y += speed;
        case .DOWN;       position.y -= speed;
        // Move camera relative to direction
        case .LEFT;       dx = -1;
        case .RIGHT;      dx =  1;
        case .FORTH;      dy = -1;
        case .BACK;       dy =  1;
        case .AWAY_FROM;  dz = -1;
        case .TOWARD;     dz =  1;
    }

	yaw   := Yaw(camera);
	pitch := Pitch(camera);

	if dx || dy {
		angle := atan2(dy, dx);
		dir_x := cos(yaw + angle);
		dir_z := sin(yaw + angle + PI);

		position.x += dir_x * speed;
		position.z += dir_z * speed;
	} else if dz {
		cos_pitch := max(abs(cos(pitch)), .001); // Prevent visual bug when looking straight up/down

		tx := sin(yaw) * cos_pitch;
		ty := sin(pitch);
		tz := cos(yaw) * cos_pitch;

		position.x += tx * dz * speed;
		position.y -= ty * dz * speed;
		position.z += tz * dz * speed;
	}
}

CubeTriangles :: (x := 1.0, y := 1.0, z := 1.0) -> [12] Triangle3D {
    return .[
        .[ {0,0,0}, {0,y,0}, {x,y,0} ],
        .[ {0,0,0}, {x,y,0}, {x,0,0} ],
        .[ {x,0,0}, {x,y,0}, {x,y,z} ],
        .[ {x,0,0}, {x,y,z}, {x,0,z} ],
        .[ {x,0,z}, {x,y,z}, {0,y,z} ],
        .[ {x,0,z}, {0,y,z}, {0,0,z} ],
        .[ {0,0,z}, {0,y,z}, {0,y,0} ],
        .[ {0,0,z}, {0,y,0}, {0,0,0} ],
        .[ {0,y,0}, {0,y,z}, {x,y,z} ],
        .[ {0,y,0}, {x,y,z}, {x,y,0} ],
        .[ {x,0,z}, {0,0,z}, {0,0,0} ],
        .[ {x,0,z}, {0,0,0}, {x,0,0} ],
    ];
}

SphereTriangle :: (radius: float = .5, $nb_of_sectors := 10, $nb_of_stacks := 10) -> [..] Triangle3D {
    vertices : [..] Vector3;
    vertices.allocator = temp;

    sector_step := TAU / nb_of_sectors;
    stack_step  := PI  / nb_of_stacks;

    array_add(*vertices, { 0, radius, 0 });
    for i : 1..nb_of_stacks - 1 {
        for j : 0..nb_of_sectors - 1 {
            stack_angle  := PI / 2 - i * stack_step;
            sector_angle := j * sector_step;
            x := radius * cos(stack_angle) * cos(sector_angle);
            y := radius * sin(stack_angle);
            z := radius * cos(stack_angle) * sin(sector_angle);
            array_add(*vertices, .{ x, y, z });
        }
    }
    array_add(*vertices, { 0, -radius, 0 });

    triangles : [..] Triangle3D;

    for 1..nb_of_sectors {
        {
            t : Triangle3D;
            t[0] = vertices[0];
            t[1] = vertices[it];
            t[2] = vertices[it % nb_of_sectors + 1];
            array_add(*triangles, t);
        }

        {
            t : Triangle3D;
            t[0] = vertices[it                 + nb_of_sectors * (nb_of_stacks - 2)    ];
            t[1] = vertices[it % nb_of_sectors + nb_of_sectors * (nb_of_stacks - 2) + 1];
            t[2] = vertices[vertices.count - 1];
            array_add(*triangles, t);
        }
    }

    for i : 0..nb_of_stacks - 3 {
        for j : 1..nb_of_sectors {
            {
                t : Triangle3D;
                t[0] = vertices[j                 + nb_of_sectors * i        ];
                t[1] = vertices[j % nb_of_sectors + nb_of_sectors * i     + 1];
                t[2] = vertices[j % nb_of_sectors + nb_of_sectors * (i+1) + 1];
                array_add(*triangles, t);
            }

            {
                t : Triangle3D;
                t[0] = vertices[j                 + nb_of_sectors * i        ];
                t[1] = vertices[j                 + nb_of_sectors * (i+1)    ];
                t[2] = vertices[j % nb_of_sectors + nb_of_sectors * (i+1) + 1];
                array_add(*triangles, t);
            }
        }
    }

    return triangles;
}