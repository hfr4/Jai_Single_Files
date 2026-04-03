ApplicationTitle  :: "Contact";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 64);
}

ApplicationReset :: () {
	my_bodyB.size = { 100, 200 };
	my_bodyA.size = { 200, 150 };

	my_bodyB.transform.xy = { 400, 400 };
	my_bodyA.transform.xy = { 600, 600 };
}

ApplicationEvents :: () {
	if Down("A") my_bodyB.transform.z -= .05;
	if Down("E") my_bodyB.transform.z += .05;

	if Down("Q") my_bodyA.transform.z -= .05;
	if Down("D") my_bodyA.transform.z += .05;

	if Down(.ARROW_LEFT)  my_bodyB.transform.x -= 3.0;
	if Down(.ARROW_RIGHT) my_bodyB.transform.x += 3.0;
	if Down(.ARROW_UP)    my_bodyB.transform.y -= 3.0;
	if Down(.ARROW_DOWN)  my_bodyB.transform.y += 3.0;
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
	Draw(my_bodyA, { 0, 1, 0, 1 });
	Draw(my_bodyB, { 1, 0, 0, 1 });

	PushAlignment(.CENTER);

	{
		PushTranslation(my_bodyA.transform.xy);
		PushColor(.GREEN);
		DrawText(my_font, "A");
	}

	{
		PushTranslation(my_bodyB.transform.xy);
		PushColor(.RED);
		DrawText(my_font, "B");
	}

	count, contacts := ComputeContacts(*my_bodyA, *my_bodyB);

	for 0..count - 1 {
		using contact := contacts[it];

		pA := MyTransform(my_bodyA.transform, contact.rA);
        pB := MyTransform(my_bodyB.transform, contact.rB);

		{
			PushWidth(10);
			PushColor(.GREEN);
			DrawPoint(pA);
			PushColor(.RED);
			DrawPoint(pB);
		}

		{
			PushTranslation((pA + pB) / 2);
			DrawText(my_font, "%", it);
		}

		using feature;

		{
			PushTranslation(100, 50.0 + 100.0 * it);
			DrawText(my_font, "% : R=%; I=%", it, (ifx referent == *my_bodyA then "A" else "B"), (ifx referent == *my_bodyA then "B" else "A"));
		}

		{
			PushTranslation(ApplicationRectangle().w / 2 + 100.0, 50.0 + 100.0 * it);
			DrawText(my_font, "iR:% oR:% iI:% oI:%", iR, oR, iI, oI);
		}
	}
}

my_font : *Font;

my_bodyA: Body;
my_bodyB: Body;

Body :: struct {
	size      : Vector2;
	transform : Vector3;
}

Contact :: struct {
    rA, rB  : Vector2;
    normal  : Vector2;

	feature : FeaturePair;

	referent, incident : *Body;
	referent_index, incident_index: int;
}

FeaturePair :: struct {
    iR, oR, iI, oI: EdgeNumbers;
    #overlay (iR) value : s32;
}

ComputeContacts :: (A: *Body, B: *Body) -> int, [2] Contact {
	contacts_count := 0;
	contacts: [2] Contact;

	hA    := A.size * 0.5;
	hB    := B.size * 0.5;

	pA    := A.transform.xy;
	pB    := B.transform.xy;

	RotA  := Rotation(A.transform.z);
	RotB  := Rotation(B.transform.z);

	RotAT := Transpose(RotA);
	RotBT := Transpose(RotB);

	dp    := pB - pA;
	dA    := RotAT * dp;
	dB    := RotBT * dp;

	C     := RotAT * RotB;
	absC  := Abs(C);
	absCT := Transpose(absC);

	faceA := abs(dA) - hA - absC * hB;
	if faceA.x > 0.0 || faceA.y > 0.0 return contacts_count, contacts;

	faceB := abs(dB) - absCT * hA - hB;
	if faceB.x > 0.0 || faceB.y > 0.0 return contacts_count, contacts;

	// Find best axis
	// The normal points from A to B

	RELATIVETOL :: 0.95;
	ABSOLUTETOL :: 0.01;

	axis       : enum { AX; AY; BX; BY; } = .AX;
	separation := faceA.x;
	normal     := ifx dA.x > 0.0 then Column(RotA, 0) else Column(-1 * RotA, 0);

	if faceA.y > RELATIVETOL * separation + ABSOLUTETOL * hA.y {
		axis       = .AY;
		separation = faceA.y;
		normal     = ifx dA.y > 0.0 then Column(RotA, 1) else Column(-1 * RotA, 1);
	}

	if faceB.x > RELATIVETOL * separation + ABSOLUTETOL * hB.x {
		axis       = .BX;
		separation = faceB.x;
		normal     = ifx dB.x > 0.0 then Column(RotB, 0) else Column(-1 * RotB, 0);
	}

	if faceB.y > RELATIVETOL * separation + ABSOLUTETOL * hB.y {
		axis       = .BY;
		separation = faceB.y;
		normal     = ifx dB.y > 0.0 then Column(RotB, 1) else Column(-1 * RotB, 1);
	}

	// Setup clipping plane data based on the separating axis
	front, side:             float;
	frontNormal, sideNormal: Vector2;
	negSide, posSide:        float;
	negEdge, posEdge:        EdgeNumbers;
	incident_edge:           [2] ClipVertex;

	// Compute the clipping lines and the line segment to be clipped.
	if axis == {
		case .AX;
			frontNormal   = normal;
			front         = dot(pA, frontNormal) + hA.x;
			sideNormal    = Column(RotA, 1);
			side          = dot(pA, sideNormal);
			negSide       = -side + hA.y;
			posSide       =  side + hA.y;
			negEdge       = .EDGE3;
			posEdge       = .EDGE1;
			incident_edge = ComputeIncidentEdge(hB, pB, RotB, frontNormal);

		case .AY;
			frontNormal   = normal;
			front         = dot(pA, frontNormal) + hA.y;
			sideNormal    = Column(RotA, 0);
			side          = dot(pA, sideNormal);
			negSide       = -side + hA.x;
			posSide       =  side + hA.x;
			negEdge       = .EDGE2;
			posEdge       = .EDGE4;
			incident_edge = ComputeIncidentEdge(hB, pB, RotB, frontNormal);

		case .BX;
			frontNormal   = -normal;
			front         = dot(pB, frontNormal) + hB.x;
			sideNormal    = Column(RotB, 1);
			side          = dot(pB, sideNormal);
			negSide       = -side + hB.y;
			posSide       =  side + hB.y;
			negEdge       = .EDGE3;
			posEdge       = .EDGE1;
			incident_edge = ComputeIncidentEdge(hA, pA, RotA, frontNormal);

		case .BY;
			frontNormal   = -normal;
			front         = dot(pB, frontNormal) + hB.y;
			sideNormal    = Column(RotB, 0);
			side          = dot(pB, sideNormal);
			negSide       = -side + hB.x;
			posSide       =  side + hB.x;
			negEdge       = .EDGE2;
			posEdge       = .EDGE4;
			incident_edge = ComputeIncidentEdge(hA, pA, RotA, frontNormal);
	}

	// clip other face with 5 box planes (1 face plane, 4 edge planes)

	np, clip_points1 := ClipSegmentWithLine(incident_edge, -sideNormal, negSide, negEdge);
	if np < 2 return contacts_count, contacts;

	np=, clip_points2 := ClipSegmentWithLine(clip_points1, sideNormal, posSide, posEdge);
	if np < 2 return contacts_count, contacts;

	// Due to roundoff, it is possible that clipping removes all points.
	for i: 0..1 {
		separation := dot(frontNormal, clip_points2[i].value) - front;

		if separation <= 0 {
			contacts[contacts_count].normal = -normal;

			// slide contact point onto reference face (easy to cull)
			contacts[contacts_count].rA      = Transpose(RotA) * (clip_points2[i].value - frontNormal * separation - pA);
			contacts[contacts_count].rB      = Transpose(RotB) * (clip_points2[i].value - pB);
			contacts[contacts_count].feature = clip_points2[i].feature;

			contacts[contacts_count].referent  = A;
			contacts[contacts_count].incident  = B;

			if axis == .BX || axis == .BY {
				swap(*contacts[contacts_count].feature.iR, *contacts[contacts_count].feature.iI);
				swap(*contacts[contacts_count].feature.oR, *contacts[contacts_count].feature.oI);

				contacts[contacts_count].referent  = B;
				contacts[contacts_count].incident  = A;

				contacts[contacts_count].rA = Transpose(RotA) * (clip_points2[i].value - pA);
				contacts[contacts_count].rB = Transpose(RotB) * (clip_points2[i].value - frontNormal * separation - pB);
			}

			contacts_count += 1;
		}
	}

	return contacts_count, contacts;
}

ClipSegmentWithLine :: (segment: [2] ClipVertex, normal: Vector2, offset: float, clipEdge: EdgeNumbers) -> int, [2] ClipVertex {
	count := 0;
	vertices: [2] ClipVertex;

	distance0 := dot(normal, segment[0].value) - offset;
	distance1 := dot(normal, segment[1].value) - offset;

	if distance0 <= 0.0 { vertices[count] = segment[0]; count += 1; }
	if distance1 <= 0.0 { vertices[count] = segment[1]; count += 1; }

	if distance0 * distance1 < 0.0 {
		interp := distance0 / (distance0 - distance1);

		vertices[count].value = segment[0].value + (segment[1].value - segment[0].value) * interp;

		if distance0 > 0.0 {
			vertices[count].feature    = segment[0].feature;
			vertices[count].feature.iR = clipEdge;
			vertices[count].feature.iI = .NONE;
		} else {
			vertices[count].feature    = segment[1].feature;
			vertices[count].feature.oR = clipEdge;
			vertices[count].feature.oI = .NONE;
		}

		count += 1;
	}

	return count, vertices;
}

ComputeIncidentEdge :: (h: Vector2, pos: Vector2, rot: Matrix2, normal: Vector2) -> [2] ClipVertex {
	edge: [2] ClipVertex;

	RotT := Transpose(rot);
	n    := -(RotT * normal);
	nAbs := abs(n);

	if nAbs.x > nAbs.y {
		if Sign(n.x) > 0.0 {
			edge[0].value      = .{ h.x, -h.y };
			edge[0].feature.iI = .EDGE3;
			edge[0].feature.oI = .EDGE4;

			edge[1].value      = .{ h.x, h.y };
			edge[1].feature.iI = .EDGE4;
			edge[1].feature.oI = .EDGE1;
		} else {
			edge[0].value      = .{ -h.x, h.y };
			edge[0].feature.iI = .EDGE1;
			edge[0].feature.oI = .EDGE2;

			edge[1].value      = .{ -h.x, -h.y };
			edge[1].feature.iI = .EDGE2;
			edge[1].feature.oI = .EDGE3;
		}
	} else {
		if Sign(n.y) > 0.0 {
			edge[0].value      = .{ h.x, h.y };
			edge[0].feature.iI = .EDGE4;
			edge[0].feature.oI = .EDGE1;

			edge[1].value      = .{ -h.x, h.y };
			edge[1].feature.iI = .EDGE1;
			edge[1].feature.oI = .EDGE2;
		} else {
			edge[0].value      = .{ -h.x, -h.y };
			edge[0].feature.iI = .EDGE2;
			edge[0].feature.oI = .EDGE3;

			edge[1].value      = .{ h.x, -h.y };
			edge[1].feature.iI = .EDGE3;
			edge[1].feature.oI = .EDGE4;
		}
	}

	edge[0].value = pos + rot * edge[0].value;
	edge[1].value = pos + rot * edge[1].value;

	return edge;
}

EdgeNumbers :: enum u8 {
	NONE  :: 0;
	EDGE1 :: 1;
	EDGE2 :: 2;
	EDGE3 :: 3;
	EDGE4 :: 4;
}

ClipVertex :: struct {
	value   : Vector2;
	feature : FeaturePair;
}

Rotation :: inline (angle: float) -> Matrix2 {
    c := cos(angle);
    s := sin(angle);
    return { c, -s, s, c };
}

Transpose :: (m: *Matrix2) {
    swap(*m.coef[0][1], *m.coef[1][0]);
}

Transpose :: (mconst: Matrix2) -> Matrix2 {
    m := mconst;
    swap(*m.coef[0][1], *m.coef[1][0]);
    return m;
}

MyTransform :: (transform: Vector3, v: Vector2) -> Vector2 {
    return Rotation(transform.z) * v + transform.xy;
}

Abs :: inline (a: Matrix2) -> Matrix2 {
    m : Matrix2 = ---;
    m.v[0] = abs(a.v[0]);
    m.v[1] = abs(a.v[1]);
    return m;
}

Column :: (using matrix: Matrix2, i: int) -> Vector2 {
    return { coef[0][i], coef[1][i] };
}

Column :: (using matrix: Matrix3, i: int) -> Vector3 {
    return { coef[0][i], coef[1][i], coef[2][i] };
}

Draw :: (using body: Body, color: Vector4) {
    R := Rotation(transform.z);

    v0 := R * Vector2.{ -size.x * 0.5, -size.y * 0.5 } + Vector2.{ transform.x, transform.y };
    v1 := R * Vector2.{  size.x * 0.5, -size.y * 0.5 } + Vector2.{ transform.x, transform.y };
    v2 := R * Vector2.{  size.x * 0.5,  size.y * 0.5 } + Vector2.{ transform.x, transform.y };
    v3 := R * Vector2.{ -size.x * 0.5,  size.y * 0.5 } + Vector2.{ transform.x, transform.y };

	bg_color := color;
	bg_color.w *= .2;

	PushAlignment(.CENTER);
	PushColor(color);

	{
		PushTranslation((v0 + v1) / 2);
		DrawText(my_font, "1");
	}

	{
		PushTranslation((v1 + v2) / 2);
		DrawText(my_font, "4");
	}

	{
		PushTranslation((v2 + v3) / 2);
		DrawText(my_font, "3");
	}

	{
		PushTranslation((v3 + v0) / 2);
		DrawText(my_font, "2");
	}

	{
		PushColor(bg_color);
		PushMode(.FILL);
		DrawPolygon(.[ v0, v1, v2, v3 ]);

		PushColor(color);
		PushMode(.LINE);
		PushWidth(2);
		DrawPolygon(.[ v0, v1, v2, v3 ]);
	}
}







/*



make_rectangle :: (center: Vector2, width: float, height: float, mass: float, elasticity: float, friction: float) -> Collider {
    vertices := Vector2.[
        .{ center.x - width / 2.0, center.y - height / 2.0 },
        .{ center.x + width / 2.0, center.y - height / 2.0 },
        .{ center.x + width / 2.0, center.y + height / 2.0 },
        .{ center.x - width / 2.0, center.y + height / 2.0 },
    ];

    collider : Collider;
    collider.shape       = make_polygon_shape(vertices);

	return collider;
}

Collider :: struct {
    using shape        : Shape;
    position           : Vector2;
    rotation           : float;
    inv_mass           : float;
    inv_inertia        : float;
    elasticity         : float;
    friction           : float;
    linear_velocity    : Vector2;
    angular_velocity   : float;
    force_accumulator  : Vector2;
    torque_accumulator : float;
    userdata           : *void;
}

MyContact :: struct {
    A, B     : *Collider;
    anchor_A : MyAnchor;
    anchor_B : MyAnchor;
    normal   : Vector2;
    depth    : float;

	ref, inc : *Collider;
	ref_index, inc_index: int;
}

MySegment :: [2] Vector2;


polygon_polygon :: (A: *Collider, B: *Collider) -> [2] MyContact, int {
    contacts : [2] MyContact;
    contacts_count : int;

    a_vertices := get_vertices(A.polygon);
    b_vertices := get_vertices(B.polygon);

    a_edge, a_depth := find_smallest_separating_edge_and_depth_using_SAT(a_vertices, b_vertices);
    if a_depth >= 0.0 return contacts, contacts_count;

    b_edge, b_depth := find_smallest_separating_edge_and_depth_using_SAT(b_vertices, a_vertices);
    if b_depth >= 0.0 return contacts, contacts_count;

    reference_is_A := a_depth > b_depth;

    ref_vertices    := ifx reference_is_A then a_vertices else b_vertices;
    inc_vertices    := ifx reference_is_A then b_vertices else a_vertices;
    ref_edge        := ifx reference_is_A then a_edge     else b_edge;
    ref_edge_normal := segment_normal(ref_edge);
    inc_edge        := find_edge_pointed_by_direction(inc_vertices, ref_edge_normal);

    clip, clip_count := clip_segment_with_polygon(inc_edge, ref_vertices);
    if !clip_count return contacts, contacts_count;

    for 0..clip_count - 1 {
        depth := dot(ref_edge[0] - clip[it], ref_edge_normal);

        EPSILON :: 0.05;
        if depth < EPSILON continue;

        world_point_on_ref := clip[it];
        world_point_on_inc := clip[it] + ref_edge_normal * depth;
        world_point_on_A   := ifx reference_is_A then world_point_on_ref else world_point_on_inc;
        world_point_on_B   := ifx reference_is_A then world_point_on_inc else world_point_on_ref;
        contact_normal     := ifx reference_is_A then ref_edge_normal    else -ref_edge_normal;

        contact : MyContact;
        contact.A        = A;
        contact.B        = B;
        contact.anchor_A = make_anchor(A, world_point_on_A);
        contact.anchor_B = make_anchor(B, world_point_on_B);
        contact.normal   = contact_normal;
        contact.depth    = depth;

        contacts[contacts_count] = contact;
        contacts_count += 1;
    }

    return contacts, contacts_count;
}

clip_segment_with_polygon :: (segment: MySegment, vertices: [] Vector2) -> MySegment, int {
    clipped := segment;
    count: int;

    for i : 0..vertices.count - 1 {
        j := (i + 1) % vertices.count;

        edge : MySegment = .[ vertices[i], vertices[j] ];
        clipped, count = clip_segment_with_line(clipped, edge);

        if count != 2 break;
    }

    return clipped, count;
}

clip_segment_with_line :: (segment: MySegment, line: MySegment) -> MySegment, int {
    clipped : MySegment;
    count : int;

    c0 := cross(segment[0] - line[0], line[1] - line[0]);
    c1 := cross(segment[1] - line[0], line[1] - line[0]);

    if c0 <= 0.0 {
        clipped[count] = segment[0];
        count += 1;
    }

    if c1 <= 0.0 {
        clipped[count] = segment[1];
        count += 1;
    }

    if c0 * c1 < 0.0 {
        clipped[count] = lerp(segment[0], segment[1], c0 / (c0 - c1));
        count += 1;

        if c1 < 0.0 swap(*clipped[0], *clipped[1]);
    }

    return clipped, count;
}

perpendicular :: (using v: Vector2) -> Vector2 #expand {
    return .{ -y, x };
}

cross :: (a: Vector2, b: Vector2) -> float #expand {
    return a.x * b.y - b.x * a.y;
}

segment_normal :: (segment: MySegment) -> Vector2 {
    return perpendicular(normalize(segment[0] - segment[1]));
}

find_smallest_separating_edge_and_depth_using_SAT :: (vertices_a: [] Vector2, vertices_b: [] Vector2) -> MySegment, float {
    result: MySegment;
    depth := -FLOAT32_INFINITY;

    for i: 0..vertices_a.count - 1 {
        j := (i + 1) % vertices_a.count;

        edge : MySegment = .[ vertices_a[i], vertices_a[j] ];
        normal := segment_normal(edge);

        min_proj := FLOAT32_INFINITY;
        for b: vertices_b {
            proj := dot((b - edge[0]), normal);
            if min_proj > proj {
                min_proj = proj;
            }
        }

        if depth < min_proj {
            depth  = min_proj;
            result = edge;
        }
    }

    return result, depth;
}

find_edge_pointed_by_direction :: (vertices: [] Vector2, dir: Vector2) -> MySegment {
    result: MySegment;

    min_proj := FLOAT32_INFINITY;

    for i : 0..vertices.count - 1 {
        j := (i + 1) % vertices.count;

        edge   : MySegment = .[ vertices[i], vertices[j] ];
        normal := segment_normal(edge);
        proj   := dot(normal, dir);

        if proj < min_proj {
            min_proj = proj;
            result   = edge;
        }
    }

    return result;
}

MyAnchor :: struct {
    collider    : *Collider;
    local_point : Vector2;
}

make_anchor :: (using collider: *Collider, world_point: Vector2) -> MyAnchor {
    return { collider, world_to_local(collider, world_point) };
}

get_position :: (using anchor: MyAnchor) -> Vector2 {
    return local_to_world(collider, local_point);
}


Shape_Kind :: enum {
    CIRCLE;
    POLYGON;
}

Shape :: union kind : Shape_Kind {
    .CIRCLE,,  circle  : MyCircle;
    .POLYGON,, polygon : MyPolygon;
}

MyCircle :: struct {
    radius : float;
}

MyPolygon :: struct {
    MAX_VERTICES :: 8;

    count    : int;
    vertices : [MAX_VERTICES] Vector2;
}

get_vertices :: (using polygon: MyPolygon) -> [] Vector2 {
    return { count, vertices.data };
}


local_to_world :: (using collider: *Collider, local_point: Vector2) -> Vector2 {
	return rotate(local_point, rotation) + position;
}

world_to_local :: (using collider: *Collider, world_point: Vector2) -> Vector2 {
	return rotate(world_point - position, -rotation);
}


make_polygon_shape :: (vertices: [] Vector2) -> Shape {
    using shape: Shape;
    kind = .POLYGON;

    polygon.count = vertices.count;
    for vertices polygon.vertices[it_index] = it;

    return shape;
}

*/