ApplicationTitle  :: "Crawl";
ApplicationWidth  :: 1600;
ApplicationHeight :: 900;

ApplicationInit :: () {
    first := CL(ApplicationRectangle()) + { 300, 0 };
    last  := CR(ApplicationRectangle()) - { 300, 0 };

    vertebrae_length := distance(first, last) / my_spine.count;

    my_spine[0] = MakeSegmentFromPolar(first, 0.0, vertebrae_length );
    for 1..my_spine.count - 1 {
        my_spine[it] = MakeSegmentFromPolar(my_spine[it - 1].b, 0.0, vertebrae_length );
    }

    for 0..my_spine.count / 2 - 1 {
        i := it * 2;
        j := it * 2 + 1;

        pin := my_spine[i].b;

        my_hands[i] = MakeSegmentFromVector(pin,  Normal(my_spine[i]) * 200.0).b;
        my_hands[j] = MakeSegmentFromVector(pin, -Normal(my_spine[i]) * 200.0).b;

        my_arms[i][0] = MakeSegmentFromVector(pin            ,  Normal(my_spine[i]) * 100.0);
        my_arms[i][1] = MakeSegmentFromVector(my_arms[i][0].b,  Normal(my_spine[i]) * 100.0);

        my_arms[j][0] = MakeSegmentFromVector(pin            , -Normal(my_spine[i]) * 100.0);
        my_arms[j][1] = MakeSegmentFromVector(my_arms[j][0].b, -Normal(my_spine[i]) * 100.0);
    }
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    mp := MousePositionOnApplication();

    if Down(.MOUSE_BUTTON_LEFT) {
        DragA(*my_spine[0], lerp(my_spine[0].a, mp, 0.1));
    }

    for 1..my_spine.count - 1 {
        DragA(*my_spine[it], my_spine[it - 1].b);
    }

    for 0..my_spine.count / 2 - 1 {
        i := it * 2;
        j := it * 2 + 1;

        if distance(my_hands[i], my_spine[i].b) > 150.0 {
            c := my_spine[i].b - Normal(my_spine[i]) * 100.0 - Direction(my_spine[i]) * 100.0;
            my_hands[i] = RandomPoint(MakeCircle(c, 30.0));
        }

        if distance(my_hands[j], my_spine[j].b) > 150.0 {
            c := my_spine[j].b + Normal(my_spine[i]) * 100.0 - Direction(my_spine[i]) * 100.0;
            my_hands[j] = RandomPoint(MakeCircle(c, 30.0));
        }

        {
            i_target := my_hands[i];
            DragB(*my_arms[i][1], i_target);
            DragB(*my_arms[i][0], my_arms[i][1].a);

            i_pin := my_spine[i].b;
            SetA(*my_arms[i][0], i_pin);
            DragA(*my_arms[i][1], my_arms[i][0].b);
        }

        {
            j_target := my_hands[j];
            DragB(*my_arms[j][1], j_target);
            DragB(*my_arms[j][0], my_arms[j][1].a);

            j_pin := my_spine[i].b;
            SetA(*my_arms[j][0], j_pin);
            DragA(*my_arms[j][1], my_arms[j][0].b);
        }
    }
}

ApplicationUpdate :: (dt: float) {
}

ApplicationRender :: () {
    head_radius := 10.0;
    tail_radius := 5.0;

    for my_spine {
        percent := cast(float) it_index / my_spine.count;
        diameter := (head_radius * 2.0) - (tail_radius * 2.0) * percent;

        PushWidth(diameter);
        DrawSegment(it);
    }

    head := my_spine[0].a;
    tail := my_spine[my_spine.count - 1].b;

    PushColor(.RED);
    DrawCircle(MakeCircle(head, head_radius));
    DrawCircle(MakeCircle(tail, tail_radius));

    for my_arms {
        PushWidth(5);
        PushColor(.GREEN);
        DrawSegment(it[0]);
        DrawSegment(it[1]);
    }

    for my_hands {
        PushWidth(10);
        PushColor(.RED);
        DrawPoint(it);
    }
}

Arm :: [2] Segment;

VERTEBRAES_COUNT :: 30;

my_spine : [VERTEBRAES_COUNT] Segment;
my_arms  : [VERTEBRAES_COUNT] Arm;
my_hands : [VERTEBRAES_COUNT] Vector2;