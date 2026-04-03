ApplicationTitle  :: "Text Align";
ApplicationWidth  :: 300;
ApplicationHeight :: 300;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 54);
}

ApplicationReset :: () {
    pos = ApplicationCenter();;
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.MOUSE_BUTTON_LEFT) pos = MousePositionOnApplication();

    if Pressed("V") flip ^= .VERTICAL;
    if Pressed("H") flip ^= .HORIZONTAL;
    if Pressed("R") should_rotate = !should_rotate;

    if Pressed("7") align = .TL;
    if Pressed("8") align = .TC;
    if Pressed("9") align = .TR;

    if Pressed("4") align = .CL;
    if Pressed("5") align = .CENTER;
    if Pressed("6") align = .CR;

    if Pressed("1") align = .BL;
    if Pressed("2") align = .BC;
    if Pressed("3") align = .BR;

    rot = ifx should_rotate then cast(float) seconds_since_init() / 2.0;
}

ApplicationUpdate :: (dt: float) {

}

ApplicationRender :: () {
    {
        PushTranslation(pos);
        PushRotation(rot);
        PushColor(.WHITE);
        PushAlignment(align);
        PushFlip(flip);
        DrawText(my_font, "Hello world !");
    }

    {
        PushMode(.LINE);
        PushColor(.GREEN);
        for my_font.current_quads DrawPolygon(Vector2.[ it.p0, it.p1, it.p2, it.p3 ]);
    }

    {
        PushTranslation(10, 10);
        DrawText(my_font, "Hello Sailor !");
    }

    {
        PushColor(.RED);
        PushWidth(5.0);
        DrawPoint(pos);
    }
}

rot    : float;
pos    : Vector2;
align  : Drawing_Alignment = .CENTER;
flip   : Flip_Flag = xx 0;

should_rotate: bool;

my_font : *Font;