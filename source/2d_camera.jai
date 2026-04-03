ApplicationTitle  :: "2D Camera";
ApplicationWidth  :: 1200;
ApplicationHeight :: 1200;

ApplicationInit :: () {
    room0 = ApplicationRectangle();
    room1 = ApplicationRectangle();
    room2 = ApplicationRectangle();
    room3 = ApplicationRectangle();

    player = MakeRectangleFromCenter(Center(room1), 150);

    texture = LoadTexture("assets/2d_camera/yotsuba.png");
    font    = LoadFont("assets/font.ttf", 64);

    SetTL(*room1, TR(room0));
    SetTL(*room2, BL(room0));
    SetTL(*room3, BR(room0));

    Resize(*room0, -100);
    Resize(*room1, -100);
    Resize(*room2, -100);
    Resize(*room3, -100);

    SetFocus(*my_camera, Center(room0));
}

ApplicationReset :: () {
    my_camera.translation = Center(room0);
}

ApplicationEvents :: () {
    if Down("Z") player.y -= 10.0;
    if Down("S") player.y += 10.0;
    if Down("Q") player.x -= 10.0;
    if Down("D") player.x += 10.0;
}

ApplicationUpdate :: (dt: float) {
    if      Colliding(player, room0) Lerp(*my_camera.translation, Center(room0), 0.1);
    else if Colliding(player, room1) Lerp(*my_camera.translation, Center(room1), 0.1);
    else if Colliding(player, room2) Lerp(*my_camera.translation, Center(room2), 0.1);
    else if Colliding(player, room3) Lerp(*my_camera.translation, Center(room3), 0.1);
}

ApplicationRender :: () {
        {
            PushCamera(my_camera);

            DrawTexture(texture, player);

            {
                PushMode(.LINE);
                PushWidth(10.0);
                PushColor(.YELLOW);
                DrawRectangle(player);
            }

            {
                PushTranslation(TC(player) - { 0, 30 });
                PushAlignment(.CENTER);
                DrawText(font, "Inside camera");
            }

            {
                PushMode(.LINE);
                PushWidth(3.0);

                DrawRectangle(room0);
                DrawRectangle(room1);
                DrawRectangle(room2);
                DrawRectangle(room3);
            }
        }

        {
            text := "Ouside camera";
            pos  := Vector2.{ 100, 100 };
            size := Size(font, text);

            PushColor(.RED);
            DrawRectangle(MakeRectangle(pos, size));
            {
                PushTranslation(pos);
                DrawText(font, text);
            }

            PushTranslation(100, 200);
            DrawTexture(texture);
        }
}

my_camera : Camera;

player : Rectangle;

font    : *Font;
texture : Texture;

room0: Rectangle;
room1: Rectangle;
room2: Rectangle;
room3: Rectangle;