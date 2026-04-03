ApplicationTitle  :: "Crawl";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    c := ApplicationCenter();

    my_segment = { c + { 100, 100 }, c - { 100, 100 } };
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    mp := MousePositionOnApplication();

    if Down(.CTRL) {
        if Down(.MOUSE_BUTTON_LEFT)  DragA(*my_segment, lerp(my_segment.a, mp, 0.1));
        if Down(.MOUSE_BUTTON_RIGHT) DragB(*my_segment, lerp(my_segment.b, mp, 0.1));
    } else if Down(.SHIFT) {
        if Down(.MOUSE_BUTTON_LEFT)  RotateAroundA(*my_segment, .01 * TAU );
        if Down(.MOUSE_BUTTON_RIGHT) RotateAroundB(*my_segment, .01 * TAU);
    } else {
        if Down(.MOUSE_BUTTON_LEFT)  SetA(*my_segment, lerp(my_segment.a, mp, 0.1));
        if Down(.MOUSE_BUTTON_RIGHT) SetB(*my_segment, lerp(my_segment.b, mp, 0.1));
    }
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
    {
        PushWidth(3);
        DrawSegment(my_segment);
    }

    {
        PushWidth(10);

        PushColor(.GREEN);
        DrawPoint(my_segment.a);

        PushColor(.RED);
        DrawPoint(my_segment.b);
    }
}

my_segment: Segment;
