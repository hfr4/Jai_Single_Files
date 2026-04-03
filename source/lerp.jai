ApplicationTitle  :: "Lerp";
ApplicationWidth  :: 800;
ApplicationHeight :: 800;

my_font : *Font;

my_position : Spring(Vector2Int);

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 64);
}

ApplicationReset :: () {
    Init(*my_position, { 100, 100 });
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        my_position.target = ToVectorInt(MousePositionOnApplication());
    }
}

ApplicationUpdate :: (dt: float) {
    Update(*my_position, dt);
}

ApplicationRender :: () {
    {
        PushTranslation(10, 10);
        DrawText(my_font, "%", my_position.value);
    }

    {
        PushWidth(10);
        PushColor(.RED);
        DrawPoint(ToVector(my_position.value));
    }
}