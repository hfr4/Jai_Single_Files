ApplicationTitle  :: "Transform";
ApplicationWidth  :: 1200;
ApplicationHeight :: 1200;

ApplicationInit :: () {
    default_texture = LoadTexture("assets/transform/yotsuba.png");
    default_font    = LoadFont("assets/font.ttf", 72);
}

ApplicationReset :: () {

}

ApplicationEvents :: () {

}

ApplicationUpdate :: (dt: float) {
    if Pressed(.ESCAPE) Quit();
}

ApplicationRender :: () {
    {
        PushColor(.GREY);
        DrawRectangle(ApplicationRectangle());
    }

    r := MakeRectangleFromCenter(ApplicationCenter(), { 500, 200 });

    {
        PushTranslation(TR(r));
        PushRotation(xx seconds_since_init());
        DrawText(default_font, "Hello World");
    }

    {
        transform : Transform;
        transform.rotation     = xx seconds_since_init();
        transform.translation  = TL(r);
        transform.scaling      = { 2.0, 1.0 };
        PushTransform(transform);
        DrawText(default_font, "Hello World");
    }

    {
        PushMode(.LINE);
        DrawRectangle(r);
    }

    {
        PushRotation(xx seconds_since_init());
        DrawTexture(default_texture, r);
    }

    {
        transform : Transform;
        transform.rotation     = xx seconds_since_init();
        transform.translation  = BR(r);
        transform.scaling      = { 2.0, 2.0 };
        PushTransform(transform);

        DrawTexture(default_texture);
    }

    {
        transform : Transform;
        transform.rotation    = xx seconds_since_init();
        transform.translation = BL(r);
        transform.scaling     = { 1.0, 2.0 };
        PushTransform(transform);

        DrawTexture(default_texture);
    }
}

default_texture : Texture;
default_font    : *Font;