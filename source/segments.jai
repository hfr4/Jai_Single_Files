ApplicationTitle  :: "Segments";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 72);
}

ApplicationReset :: () {
    my_segment.a = ApplicationCenter() - { 200, 100 };
    my_segment.b = ApplicationCenter() + { 200, 100 };

    my_segment2.a = my_segment.a + { 200, 100 };
    my_segment2.b = my_segment.b + { 200, 100 };
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        mp := MousePositionOnApplication();

        ca := Circle.{ my_segment.a.x, my_segment.a.y, 15.0 };
        cb := Circle.{ my_segment.b.x, my_segment.b.y, 15.0 };

        if      Colliding(mp, ca) move_a = true;
        else if Colliding(mp, cb) move_b = true;
    }

    if Down("S") Move(*my_segment, {  0 ,  1 });
    if Down("Q") Move(*my_segment, { -1 ,  0 });
    if Down("Z") Move(*my_segment, {  0 , -1 });
    if Down("D") Move(*my_segment, {  1 ,  0 });

    if Released(.MOUSE_BUTTON_LEFT) {
        move_a = false;
        move_b = false;
    }
}

ApplicationUpdate :: (dt: float) {
    mp := MousePositionOnApplication();

    if move_a my_segment.a = lerp(my_segment.a, mp, .2);
    if move_b my_segment.b = lerp(my_segment.b, mp, .2);
}

ApplicationRender :: () {
    {
        ca := Circle.{ my_segment.a.x, my_segment.a.y, 15.0 };
        cb := Circle.{ my_segment.b.x, my_segment.b.y, 15.0 };

        PushMode(.LINE);
        PushWidth(3);
        PushColor(.RED);

        DrawCircle(ca);
        DrawCircle(cb);
    }


    {
        color := ifx Colliding(my_segment, my_segment2) then Color.RED else Color.WHITE;
        PushColor(color);
        PushWidth(3);
        DrawSegment(my_segment);
        DrawSegment(my_segment2);
    }

    {
        pa, pb := ClosestPoints(my_segment, my_segment2);

        PushColor(.GREEN);
        PushWidth(15);
        DrawPoint(pa);
        DrawPoint(pb);
    }

    if Collinear(my_segment, my_segment2) {
        PushTranslation(10, 50);
        DrawText(*my_font, "Collinear !");
    }

    if Parallel(my_segment, my_segment2) {
        PushTranslation(10, 100);
        DrawText(*my_font, "Parallel !");
    }
}


my_segment  : Segment;
my_segment2 : Segment;

move_a : bool;
move_b : bool;

my_font : Font;