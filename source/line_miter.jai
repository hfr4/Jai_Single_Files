ApplicationTitle  :: "Line Miter";
ApplicationWidth  :: 1200;
ApplicationHeight :: 1200;

ApplicationInit :: () {
}

ApplicationReset :: () {
}

ApplicationEvents :: () {
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
    PushTranslation(100, 10);
    PushColor(1, 1, 1, .5);
    PushMode(.LINE);
    PushWidth(50);

    r   := MakeRectangleFromCenter(ApplicationCenter(), {800, 600});
    pts := Points(r);
    pts[2] = MousePositionOnApplication();
    poly := Polygon.{ pts };

    DrawPolygon(poly);
}