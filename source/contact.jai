ApplicationTitle  :: "Contact B2D";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 64);

	poly1.points = array_copy(Points(Rectangle.{ 100, 100, 200, 300 }));
	poly2.points = array_copy(Points(Rectangle.{ 500, 500, 300, 200 }));
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
	if Down("A") Rotate(*poly1, -.05);
	if Down("E") Rotate(*poly1, +.05);
	if Down("Q") Move(*poly1, { -3, 0 });
	if Down("D") Move(*poly1, { +3, 0 });
	if Down("Z") Move(*poly1, {  0,-3 });
	if Down("S") Move(*poly1, {  0,+3 });

	if Down("W") Rotate(*poly2, -.05);
	if Down("C") Rotate(*poly2, +.05);
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
	{
		PushMode(.FILL);
		PushColor(.4, 0, 0);
		DrawPolygon(poly2);
		PushColor(0, .4, 0);
		DrawPolygon(poly1);
	}


	{
		PushMode(.LINE);
		PushWidth(3);

		PushColor(.RED);
		DrawPolygon(poly2);

		PushColor(.GREEN);
		DrawPolygon(poly1);
	}

	edge1, depth1 := SAT(poly1, poly2);
	edge2, depth2 := SAT(poly2, poly1);

	collision := depth1 > 0.0 && depth2 > 0.0;

	if collision {
		if depth1 > depth2 {
			referent_edge := edge1;
    		incident_edge := find_edge_pointed_by_direction(poly2, Normal(referent_edge));

			PushWidth(3);

			PushColor(.YELLOW);
			DrawSegment(referent_edge);

			PushColor(.CYAN);
			DrawSegment(incident_edge);

			clip, clip_count := PolygonClip(incident_edge, poly1);

			for 0..clip_count - 1 {
				depth := dot(referent_edge.a - clip[it], Normal(referent_edge));

				// EPSILON :: 0.05;
				// if depth < EPSILON continue;

				// contact_normal     := ifx reference_is_A then ref_edge_normal    else -ref_edge_normal;
				// world_point_on_ref := clip[it];
				// world_point_on_inc := clip[it] + ref_edge_normal * depth;
				// world_point_on_A   := ifx reference_is_A then world_point_on_ref else world_point_on_inc;
				// world_point_on_B   := ifx reference_is_A then world_point_on_inc else world_point_on_ref;

				PushWidth(15);
				PushColor(.RED);
				DrawPoint(clip[it]);
			}
		} else {
			referent_edge := edge2;
    		incident_edge := find_edge_pointed_by_direction(poly1, Normal(referent_edge));

			PushWidth(3);

			PushColor(.YELLOW);
			DrawSegment(referent_edge);

			PushColor(.CYAN);
			DrawSegment(incident_edge);

			clip, clip_count := PolygonClip(incident_edge, poly2);

			for 0..clip_count - 1 {
				depth := dot(referent_edge.a - clip[it], Normal(referent_edge));

				// EPSILON :: 0.05;
				// if depth < EPSILON continue;

				// contact_normal     := ifx reference_is_A then ref_edge_normal    else -ref_edge_normal;
				// world_point_on_ref := clip[it];
				// world_point_on_inc := clip[it] + ref_edge_normal * depth;
				// world_point_on_A   := ifx reference_is_A then world_point_on_ref else world_point_on_inc;
				// world_point_on_B   := ifx reference_is_A then world_point_on_inc else world_point_on_ref;

				PushWidth(15);
				PushColor(.GREEN);
				DrawPoint(clip[it]);
			}
		}
	}
}

my_font : *Font;

poly1 : Polygon;
poly2 : Polygon;

SAT :: (A: Polygon, B: Polygon) -> Segment, float {
    result : Segment;
    depth := FLOAT32_INFINITY;

    for :segments segment: A {
        normal := Normal(segment);

        proj := -FLOAT32_INFINITY;
        for B proj = max(proj, dot(segment.a - it, normal));
        if depth < proj continue;

		depth  = proj;
		result = segment;
    }

    return result, depth;
}

find_edge_pointed_by_direction :: (using polygon: Polygon, direction: Vector2) -> Segment {
    edge : Segment;
    min_proj := FLOAT32_INFINITY;

    for :segments polygon {
        proj := dot( Normal(it), direction);
        if proj > min_proj continue;
		min_proj = proj;
		edge     = it;
    }

    return edge;
}

PolygonClip :: (segment: Segment, using polygon: Polygon) -> [2] Vector2, int {
    clipped := Points(segment);

    count : int;

    for :segments polygon {
        clipped, count = LineClip(clipped, it);
        if count < 2 break;
    }

    return clipped, count;
}

LineClip :: (segment: [2] Vector2, line: Segment) -> [2] Vector2, int {
    clipped : [2] Vector2;
    count   : int;

    c0 := Cross(segment[0] - line.a, Vector(line));
    c1 := Cross(segment[1] - line.a, Vector(line));

    if c0 <= 0.0 { clipped[count] = segment[0]; count += 1; }
    if c1 <= 0.0 { clipped[count] = segment[1]; count += 1; }

    if c0 * c1 < 0.0 {
        clipped[count] = lerp(segment[0], segment[1], c0 / (c0 - c1));
        count += 1;
        if c1 < 0.0 swap(*clipped[0], *clipped[1]);
    }

    return clipped, count;
}