ApplicationTitle  :: "Animation";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    tex0 = LoadTexture("assets/animation/frame0.png");
    tex1 = LoadTexture("assets/animation/frame1.png");
    tex2 = LoadTexture("assets/animation/frame2.png");
    tex3 = LoadTexture("assets/animation/frame3.png");
    tex4 = LoadTexture("assets/animation/frame4.png");
    tex5 = LoadTexture("assets/animation/frame5.png");

    array_add(*my_animation.frames, { *tex0, 0.2 }, { *tex1, 0.2 }, { *tex2, 0.2 }, { *tex3, 0.2 }, { *tex4, 0.2 }, { *tex5, 0.2 });
}

ApplicationReset :: () {

}

ApplicationEvents :: () {

}

ApplicationUpdate :: (dt: float) {
    Update(*my_animation, dt);
}

ApplicationRender :: () {
    {
        PushColor({ .5, .7, .9, 1 });
        DrawRectangle(ApplicationRectangle());
    }

    {
        PushAlignment(.CENTER);
        PushTranslation(ApplicationCenter());
        DrawAnimation(my_animation);
    }
}

my_animation : Animation;

tex0 : Texture;
tex1 : Texture;
tex2 : Texture;
tex3 : Texture;
tex4 : Texture;
tex5 : Texture;

