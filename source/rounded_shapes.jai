ApplicationTitle :: "Rounded Shapes";
ApplicationWidth  :: 1600;
ApplicationHeight :: 1000;

ApplicationInit :: () {
}

ApplicationReset :: () {
	a.a = { 1300, 700 };
	a.b = { 1100, 800 };
	a.r = 50;

	b.rectangle = MakeRectangleFromCenter({ 400, 300 }, { 300, 200 });
	b.r = 50;

	pos    := Vector2.{ 1000, 350 };
	points := Vector2.[
		pos + { -150, -100 },
		pos + {    0, -200 },
		pos + { +150, -100 },
		pos + { +100, +100 },
		pos + { -100, +100 },
	];

    c.polygon = { array_copy(points) };
	c.r = 50.0;

	d = { 400, 750, 200, 100 };
}

ApplicationEvents :: () {
	if Pressed(.ESCAPE) Quit();
	if Pressed("R")     Reset();

	if Down(.MOUSE_BUTTON_LEFT) {
		Lerp(*a.b, MousePositionOnApplication(), .1);
	}
}

ApplicationUpdate :: (dt: float) {

}

ApplicationRender :: () {
	PushMode(.LINE);

	{
		color : Color = ifx Colliding(MousePositionOnApplication(), a) then .WHITE else .RED;
		PushColor(color);
		PushWidth(3.0);
		DrawSegment(a.segment);
		PushWidth(10.0);
		DrawRoundedSegment(a);

		PushWidth(3.0);
		DrawRectangle(BoundingBox(a));
		DrawCircle(BoundingCircle(a));
	}

	{
		color : Color = ifx Colliding(MousePositionOnApplication(), b) then .WHITE else .GREEN;
		PushColor(color);
		PushWidth(3.0);
		DrawRectangle(b.rectangle);
		PushWidth(10.0);
		DrawRoundedRectangle(b);

		PushWidth(3.0);
		DrawRectangle(BoundingBox(b));
		DrawCircle(BoundingCircle(b));
	}

	{
		Rotate(*c.polygon, .01);

		color : Color = ifx Colliding(MousePositionOnApplication(), c) then .WHITE else .CYAN;
		PushColor(color);
		PushWidth(3.0);
		DrawPolygon(c.polygon);
		PushWidth(10.0);
		DrawRoundedPolygon(c);

		PushWidth(3.0);
		DrawRectangle(BoundingBox(c));
		DrawCircle(BoundingCircle(c));
	}

	{
		color : Color = ifx Colliding(MousePositionOnApplication(), d) then .WHITE else .YELLOW;
		PushColor(color);
		PushWidth(10.0);
		DrawEllipse(d);

		PushWidth(3.0);
		DrawRectangle(BoundingBox(d));
		DrawCircle(BoundingCircle(d));
	}
}

a : Rounded_Segment;
b : Rounded_Rectangle;
c : Rounded_Polygon;
d : Ellipse;