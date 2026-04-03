ApplicationTitle  :: "Fabrik";
ApplicationWidth  :: 1600;
ApplicationHeight :: 900;

ApplicationInit :: () {
    first := TC(ApplicationRectangle()) + { 0 , 100 };
    length := 30.0;
    rope[0] = MakeSegmentFromPolar(first, 0.0, length );
    for 1..rope.count - 1 rope[it] = MakeSegmentFromPolar(rope[it - 1].b, 0.0, length);
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();
}

ApplicationUpdate :: (dt: float) {
    target := MousePositionOnApplication();

    DragB(*rope[rope.count - 1], target);
    for < 0..rope.count - 2 DragB(*rope[it], rope[it + 1].a);

    pin := TC(ApplicationRectangle()) + { 0 , 100 };

    SetA(*rope[0], pin);
    for 1..rope.count - 1 DragA(*rope[it], rope[it - 1].b);
}

ApplicationRender :: () {
    for rope {
        PushWidth(5);
        PushColor(.RED);
        DrawSegment(it);
    }
}

rope: [20] Segment;