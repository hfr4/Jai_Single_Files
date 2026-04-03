ApplicationTitle  :: "Contains";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 72);

    my_rectangle = { 100, 100, 300, 200 };
    my_polygon   = { array_copy(Vector2.[ { 300, 400 }, { 500, 400 }, { 500, 600 }, { 250, 700 } ]) };
    my_circle    = { 650, 250, 150 };
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

    PushMode(.LINE);
    PushWidth(3);

    if kind == {
        case Vector2;
            {
                PushWidth(15);
                DrawPoint(point);
            }
            PushColor(ifx Contains(my_circle   , point) then Color.RED else Color.WHITE); DrawCircle   (my_circle   );
            PushColor(ifx Contains(my_rectangle, point) then Color.RED else Color.WHITE); DrawRectangle(my_rectangle);
            PushColor(ifx Contains(my_polygon  , point) then Color.RED else Color.WHITE); DrawPolygon  (my_polygon  );

        case Segment;
            DrawSegment(segment);
            PushColor(ifx Contains(my_circle   , segment) then Color.RED else Color.WHITE); DrawCircle   (my_circle   );
            PushColor(ifx Contains(my_rectangle, segment) then Color.RED else Color.WHITE); DrawRectangle(my_rectangle);
            PushColor(ifx Contains(my_polygon  , segment) then Color.RED else Color.WHITE); DrawPolygon  (my_polygon  );

        case Circle;
            DrawCircle(circle);
            PushColor(ifx Contains(my_circle   , circle) then Color.RED else Color.WHITE); DrawCircle   (my_circle   );
            PushColor(ifx Contains(my_rectangle, circle) then Color.RED else Color.WHITE); DrawRectangle(my_rectangle);
            PushColor(ifx Contains(my_polygon  , circle) then Color.RED else Color.WHITE); DrawPolygon  (my_polygon  );

        case Rectangle;
            DrawRectangle(rectangle);
            PushColor(ifx Contains(my_circle   , rectangle) then Color.RED else Color.WHITE); DrawCircle   (my_circle   );
            PushColor(ifx Contains(my_rectangle, rectangle) then Color.RED else Color.WHITE); DrawRectangle(my_rectangle);
            PushColor(ifx Contains(my_polygon  , rectangle) then Color.RED else Color.WHITE); DrawPolygon  (my_polygon  );

        case Polygon;
            DrawPolygon(polygon);
            PushColor(ifx Contains(my_circle   , polygon) then Color.RED else Color.WHITE); DrawCircle   (my_circle   );
            PushColor(ifx Contains(my_rectangle, polygon) then Color.RED else Color.WHITE); DrawRectangle(my_rectangle);
            PushColor(ifx Contains(my_polygon  , polygon) then Color.RED else Color.WHITE); DrawPolygon  (my_polygon  );
    }
}

my_font : *Font;

Shape :: union kind : Type = Vector2 {
    point     : Vector2;
    segment   : Segment;
    circle    : Circle;
    rectangle : Rectangle;
    polygon   : Polygon;
}

my_shape : Shape;

INITIAL_POLYGON_POINTS :: Vector2.[ { -25, 25 }, { 25, 25 }, { 50, -30 }, { 0, -75 }, { -50, -30 } ];
polygon_points : [INITIAL_POLYGON_POINTS.count] Vector2;

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