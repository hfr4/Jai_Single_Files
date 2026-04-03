ApplicationTitle  :: "Isometric";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    SetFocus(*my_camera, ApplicationCenter());
}

ApplicationReset :: () {
    my_camera.transform = {};

    player_velocity         = {};
    player_is_on_the_ground = true;

    player.cube  = { { 0, 0, 0 }, { 49, 49, 49 } };
    player.color = .RED;

    obstacles[0].cube  = { { 100, 0, 0 }, { 50, 50, 50 } };
    obstacles[0].color = .GREEN;

    obstacles[1].cube  = { { 150, 0, 0 }, { 50, 50, 100 } };
    obstacles[1].color = .GREEN;

    obstacles[2].cube  = { { 200, 0, 75 }, { 100, 50, 25 } };
    obstacles[2].color = .GREEN;

    obstacles[3].cube  = { { 250, 0, 75 }, { 50, 150, 25 } };
    obstacles[3].color = .GREEN;
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();
    if Pressed("R")     Reset();

    if      Down("Z") player_velocity.y = -1 * MOVE_SPEED;
    else if Down("S") player_velocity.y = +1 * MOVE_SPEED;
    else              player_velocity.y = 0;

    if      Down("Q") player_velocity.x = -1 * MOVE_SPEED;
    else if Down("D") player_velocity.x = +1 * MOVE_SPEED;
    else              player_velocity.x = 0;

    if Pressed(.SPACEBAR) && player_is_on_the_ground  player_velocity.z = JUMP_FORCE;
}

ApplicationUpdate :: (dt: float) {
    {
        cube_prediction := player.cube;

        player_velocity.z += GRAVITY * dt;
        Move(*cube_prediction, { 0, 0, player_velocity.z });

        player_is_on_the_ground = false;

        // Check floor
        if cube_prediction.position.z <= 0 {
            cube_prediction.position.z = 0; // Snap to floor

            player_velocity.z       = 0;
            player_is_on_the_ground = true;
        }

        // Check obstacles
        for obstacles {
            if Colliding(cube_prediction, it.cube) {
                // If we are falling and hit something, stay on top
                if player_velocity.z < 0 {
                    player_velocity.z = 0;
                    player_is_on_the_ground = true;
                } else {
                    // If we hit the bottom of a block while jumping
                    player_velocity.z = -1.0;
                }

                // Keep current player Z to avoid clipping into the block
                cube_prediction.position.z = player.cube.position.z;
            }
        }

        player.cube = cube_prediction;
    }

    {
        cube_prediction := player.cube;

        Move(*cube_prediction, { player_velocity.x, player_velocity.y, 0 });
        rollback_x := false;
        rollback_y := false;

        for obstacles {
            if Colliding(cube_prediction, it.cube) {
                ZFace :: (using cube: Cube) -> Rectangle {
                    return { position.x, position.y, size.x, size.y };
                }

                r0 := ZFace(player.cube);
                r1 := ZFace(it.cube);
                
                edge_index := ClosestEdgeIndex(MinkowskiDif(r0, r1), Vector2.{ 0, 0 });

                if (edge_index == 0 || edge_index == 2) {
                    rollback_y = true;
                } else if (edge_index == 1 || edge_index == 3) {
                    rollback_x = true;
                }
            }
        }

        if !rollback_y Move(*player.cube, { 0, player_velocity.y, 0 });
        if !rollback_x Move(*player.cube, { player_velocity.x, 0, 0 });
    }

    {
        using player;
        Lerp(*my_camera.translation, { cube.position.x, Min(cube).y - Max(cube).z }, 0.1);
    }
}

ApplicationRender :: () {
    PushCamera(my_camera);

    {
        PushColor(.1, .1, .1);
        DrawRectangle(MakeRectangleFromCenter({}, { 500, 500 }));
    }

    DrawBlockV1 :: (using block: Block) {
        top   := Rectangle.{ cube.position.x, Min(cube).y - Max(cube).z              , cube.size.x, cube.size.y };
        front := Rectangle.{ cube.position.x, Min(cube).y - Max(cube).z + cube.size.y, cube.size.x, cube.size.z };

        {
            PushColor(color);

            PushAlpha(0.8);
            PushMode(.FILL);
            DrawRectangle(top);

            PushAlpha(1.0);
            PushMode(.LINE);
            DrawRectangle(top);
        }

        {
            PushColor(color);

            PushAlpha(0.5);
            PushMode(.FILL);
            DrawRectangle(front);

            PushAlpha(1.0);
            PushMode(.LINE);
            DrawRectangle(front);
        }
    }

    DrawBlockV2 :: (using block: Block) {
        min := Min(cube);
        max := Max(cube);

        ProjectToIso :: (using position: Vector3) -> Vector2 #expand {
            return { (x - y), (x + y) * 0.5 - z };
        }

        t_back  := ProjectToIso({ min.x, min.y, max.z });
        t_right := ProjectToIso({ max.x, min.y, max.z });
        t_front := ProjectToIso({ max.x, max.y, max.z });
        t_left  := ProjectToIso({ min.x, max.y, max.z });

        b_right := ProjectToIso({ max.x, min.y, min.z });
        b_front := ProjectToIso({ max.x, max.y, min.z });
        b_left  := ProjectToIso({ min.x, max.y, min.z });

        {
            PushColor(color);

            PushAlpha(0.95);
            PushMode(.FILL);
            DrawPolygon(.[ t_back, t_right, t_front, t_left ]);

            PushAlpha(1.0);
            PushMode(.LINE);
            DrawPolygon(.[ t_back, t_right, t_front, t_left ]);
        }

        {
            PushColor(color);
            PushAlpha(0.50);
            PushMode(.FILL);
            DrawPolygon(.[ b_left, b_front, t_front, t_left ]);

            PushAlpha(1.0);
            PushMode(.LINE);
            DrawPolygon(.[ b_left, b_front, t_front, t_left ]);
        }

        {
            PushColor(color);
            PushAlpha(0.75);
            PushMode(.FILL);
            DrawPolygon(.[ b_front, b_right, t_right, t_front ]);

            PushAlpha(1.0);
            PushMode(.LINE);
            DrawPolygon(.[ b_front, b_right, t_right, t_front ]);
        }
    }

    DrawBlocks :: () {
        sorted : [..] *Block;
        sorted.allocator = temp;

        array_add(*sorted, *player);
        for * obstacles array_add(*sorted, it);

        ZSortBlocks :: (ba: *Block, bb: *Block) -> float {
            a, b := ba.cube, bb.cube;
            if Max(a).x < b.position.x || Max(a).y < b.position.y || Max(a).z < b.position.z return -1.0;
            if Max(b).x < a.position.x || Max(b).y < a.position.y || Max(b).z < a.position.z return +1.0;
            return (a.position.x + a.position.y + a.position.z) - (b.position.x + b.position.y + b.position.z);
        }

        for quick_sort(sorted, ZSortBlocks) DrawBlockV1(it);
    }

    DrawBlocks();
}

Block :: struct {
    cube  : Cube;
    color : Color;
}


my_camera : Camera;

player    : Block;
obstacles : [4] Block;

player_velocity         : Vector3;
player_is_on_the_ground : bool;

GRAVITY    : float = -20.0;
JUMP_FORCE : float =  7.0;
MOVE_SPEED : float =  3.5;

#import "Sort";
