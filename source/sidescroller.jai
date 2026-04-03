ApplicationTitle  :: "Sidescroller";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    SetFocus(*my_camera, ApplicationCenter());
}

ApplicationReset :: () {
    my_camera.transform = {};
    my_camera.scaling.y = -1;

    player_velocity                  = {};
    player_is_on_the_ground          = true;
    player_is_falling_from_plateform = false;

    player.rect  = { 0, 0, 49, 49 };
    player.color = .RED;

    obstacles[0].rect  = { 100, 75, 50, 50 };
    obstacles[0].color = .GREEN;

    obstacles[1].rect  = { 150, 100, 50, 50 };
    obstacles[1].color = .GREEN;

    obstacles[2].rect  = { 200, 125, 50, 50 };
    obstacles[2].color = .GREEN;

    obstacles[3].rect  = { 250, 150, 50, 50 };
    obstacles[3].color = .GREEN;
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();
    if Pressed("R")     Reset();

    if      Down("Q") player_velocity.x = -1 * MOVE_SPEED;
    else if Down("D") player_velocity.x = +1 * MOVE_SPEED;
    else              player_velocity.x = 0;

    if Pressed(.SPACEBAR) && player_is_on_the_ground {
        if Down("S") {
            player_is_falling_from_plateform = true;
            player_is_on_the_ground = false;
        } else {
            player_velocity.y = JUMP_FORCE;
        }
    }
}

ApplicationUpdate :: (dt: float) {
    {
        rect_prediction := player.rect;

        player_velocity.y += GRAVITY * dt;
        Move(*rect_prediction, { 0, player_velocity.y });

        player_is_on_the_ground = false;

        if !player_is_falling_from_plateform {
            for obstacles {
                if Colliding(rect_prediction, it.rect) {
                    if player_velocity.y < 0 {
                        player_velocity.y = 0;
                        player_is_on_the_ground = true;
                    } else {
                        player_velocity.y = -1.0;
                    }

                    rect_prediction.y = player.rect.y;
                }
            }
        }

        // Check floor
        if rect_prediction.y <= 0 {
            rect_prediction.y       = 0; // Snap to floor
            player_velocity.y       = 0;
            player_is_on_the_ground = true;

            if player_is_falling_from_plateform {
                player_is_falling_from_plateform = false;
            }
        }

        player.rect = rect_prediction;
    }

    {
        rect_prediction := player.rect;

        Move(*rect_prediction, { player_velocity.x, player_velocity.y });
        rollback_x := false;
        rollback_y := false;

        for obstacles {
            if Colliding(rect_prediction, it.rect) {
                r0 := player.rect;
                r1 := it.rect;
                edge_index := ClosestEdgeIndex(MinkowskiDif(r0, r1), Vector2.{ 0, 0 });

                if edge_index == 0 || edge_index == 2 {
                    rollback_y = true;
                } else if edge_index == 1 || edge_index == 3 {
                    rollback_x = true;
                }
            }
        }

        if !rollback_y && !player_is_falling_from_plateform Move(*player.rect, { 0, player_velocity.y });
        if !rollback_x || player_is_falling_from_plateform  Move(*player.rect, { player_velocity.x, 0 });
    }

    {
        Lerp(*my_camera.translation, TL(player.rect), 0.1);
    }
}

ApplicationRender :: () {
    PushCamera(my_camera);

    DrawBlocks :: () {
        sorted : [..] *Block;
        sorted.allocator = temp;

        array_add(*sorted, *player);
        for * obstacles array_add(*sorted, it);

        PushMode(.FILL);
        for sorted {
            PushColor(it.color);
            PushAlpha(0.2);
            DrawRectangle(it.rect);
        }

        PushMode(.LINE);
        for sorted {
            PushColor(it.color);
            DrawRectangle(it.rect);
        }
    }

    DrawBlocks();
}

Block :: struct {
    rect  : Rectangle;
    color : Color;
}

my_camera : Camera;

obstacles : [4] Block;

player : Block;

player_velocity                  : Vector2;
player_is_on_the_ground          : bool;
player_is_falling_from_plateform : bool;

GRAVITY    : float = -20.0;
JUMP_FORCE : float =  7.0;
MOVE_SPEED : float =  3.5;

#import "Sort";
