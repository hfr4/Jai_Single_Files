ApplicationTitle  :: "Colliding";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 72);

    my_point     = { 100, 400 };
    my_segment   = { { 600, 600 }, { 700, 800 } };
    my_rectangle = { 100, 100, 300, 200 };
    my_polygon   = { array_copy(Vector2.[ { 300, 400 }, { 500, 400 }, { 500, 600 }, { 250, 700 } ]) };
    my_circle    = { 600, 300, 100 };
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed("1") my_shape.kind = Vector2;
    if Pressed("2") my_shape.kind = Segment;
    if Pressed("3") my_shape.kind = Circle;
    if Pressed("4") my_shape.kind = Rectangle;
    if Pressed("5") my_shape.kind = Polygon;

    mp := MousePositionOnApplication();
    UpdateAndMoveMyShape(mp);
}

ApplicationUpdate :: (dt: float) {
    mp := MousePositionOnApplication();
    UpdateAndMoveMyShape(mp);
}

ApplicationRender :: () {
    using my_shape;


    if kind == {
        case Vector2;
            PushMode(.LINE);
            PushWidth(15.0);
            DrawPoint(point);

            PushWidth(9.0);
            PushColor(ifx Colliding(my_point, point) then Color.RED else .WHITE);
            DrawPoint(my_point);

            PushWidth(3.0);

            PushColor(ifx Colliding(my_segment, point) then Color.RED else .WHITE);
            DrawSegment(my_segment);

            PushColor(ifx Colliding(my_circle, point) then Color.RED else .WHITE);
            DrawCircle(my_circle);

            PushColor(ifx Colliding(my_rectangle, point) then Color.RED else .WHITE);
            DrawRectangle(my_rectangle);

            PushColor(ifx Colliding(my_polygon, point) then Color.RED else .WHITE);
            DrawPolygon(my_polygon);

        case Segment;
            PushMode(.LINE);
            PushWidth(3.0);
            DrawSegment(segment);

            PushWidth(9.0);
            PushColor(ifx Colliding(my_point, segment) then Color.RED else .WHITE);
            DrawPoint(my_point);

            PushWidth(3.0);

            PushColor(ifx Colliding(my_segment, segment) then Color.RED else .WHITE);
            DrawSegment(my_segment);

            PushColor(ifx Colliding(my_circle, segment) then Color.RED else .WHITE);
            DrawCircle(my_circle);

            PushColor(ifx Colliding(my_rectangle, segment) then Color.RED else .WHITE);
            DrawRectangle(my_rectangle);

            PushColor(ifx Colliding(my_polygon, segment) then Color.RED else .WHITE);
            DrawPolygon(my_polygon);

        case Circle;
            PushMode(.LINE);
            PushWidth(3.0);
            DrawCircle(circle);

            PushWidth(9.0);
            PushColor(ifx Colliding(my_point, circle) then Color.RED else .WHITE);
            DrawPoint(my_point);

            PushWidth(3.0);

            PushColor(ifx Colliding(my_segment, circle) then Color.RED else .WHITE);
            DrawSegment(my_segment);

            PushColor(ifx Colliding(my_circle, circle) then Color.RED else .WHITE);
            DrawCircle(my_circle);

            PushColor(ifx Colliding(my_rectangle, circle) then Color.RED else .WHITE);
            DrawRectangle(my_rectangle);

            PushColor(ifx Colliding(my_polygon, circle) then Color.RED else .WHITE);
            DrawPolygon(my_polygon);

        case Rectangle;
            PushMode(.LINE);
            PushWidth(3.0);
            DrawRectangle(rectangle);

            PushWidth(9.0);
            PushColor(ifx Colliding(my_point, rectangle) then Color.RED else .WHITE);
            DrawPoint(my_point);

            PushWidth(3.0);

            PushColor(ifx Colliding(my_segment, rectangle) then Color.RED else .WHITE);
            DrawSegment(my_segment);

            PushColor(ifx Colliding(my_circle, rectangle) then Color.RED else .WHITE);
            DrawCircle(my_circle);

            PushColor(ifx Colliding(my_rectangle, rectangle) then Color.RED else .WHITE);
            DrawRectangle(my_rectangle);

            PushColor(ifx Colliding(my_polygon, rectangle) then Color.RED else .WHITE);
            DrawPolygon(my_polygon);

        case Polygon;
            PushMode(.LINE);
            PushWidth(3.0);
            DrawPolygon(polygon);

            PushWidth(9.0);
            PushColor(ifx Colliding(my_point, polygon) then Color.RED else .WHITE);
            DrawPoint(my_point);

            PushWidth(3.0);

            PushColor(ifx Colliding(my_segment, polygon) then Color.RED else .WHITE);
            DrawSegment(my_segment);

            PushColor(ifx Colliding(my_circle, polygon) then Color.RED else .WHITE);
            DrawCircle(my_circle);

            PushColor(ifx Colliding(my_rectangle, polygon) then Color.RED else .WHITE);
            DrawRectangle(my_rectangle);

            PushColor(ifx Colliding(my_polygon, polygon) then Color.RED else .WHITE);
            DrawPolygon(my_polygon);
    }
}

my_font : *Font;

Shape :: union kind : Type = Polygon {
    point     : Vector2;
    segment   : Segment;
    circle    : Circle;
    rectangle : Rectangle;
    polygon   : Polygon;
}

my_shape : Shape;
INITIAL_POLYGON_POINTS :: Vector2.[ { -50, 50 }, { 50, 50 }, { 100, -60 }, { 0, -150 }, { -100, -60 } ];
polygon_points : [INITIAL_POLYGON_POINTS.count] Vector2;

my_point     : Vector2;
my_segment   : Segment;
my_rectangle : Rectangle;
my_polygon   : Polygon;
my_circle    : Circle;

UpdateAndMoveMyShape :: (position: Vector2) {
    using my_shape;

    if kind == {
        case Vector2;
            point = position;

        case Segment;
            segment = { position + { -100, 50 }, position + { 100, -50 }};

        case Circle;
            circle = { position.x, position.y, 50 };

        case Rectangle;
            rectangle = MakeRectangleFromCenter(position, 100);

        case Polygon;
            polygon.points = polygon_points;
            for * polygon.points it.* = INITIAL_POLYGON_POINTS[it_index] + position;
    }
}