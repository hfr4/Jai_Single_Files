ApplicationTitle  :: "Spring";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 64);
}

ApplicationReset :: () {
    Init(*my_spring, { 100, 100 });
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        my_spring.target = ToVectorInt(MousePositionOnApplication());
    }
}

ApplicationUpdate :: (dt: float) {
    Update(*my_spring, dt);
}

ApplicationRender :: () {
    {
        PushColor(.1, .1, .1);
        DrawRectangle(ApplicationRectangle());
    }

    {
        PushTranslation(30, 30);
        DrawText(my_font, "%", my_spring.value);
    }

    {
        PushWidth(10);
        PushColor(.RED);
        DrawPoint(ToVector(my_spring.value));
    }
}

my_font : *Font;

my_spring : Spring(Vector2Int);