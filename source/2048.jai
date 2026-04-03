ApplicationTitle  :: "2048";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    my_font = LoadFont("assets/font.ttf", 64);
}

ApplicationReset :: () {
    InitTheGrid();
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if !moving {
        if Pressed(.ARROW_UP)    Move(.UP);
        if Pressed(.ARROW_DOWN)  Move(.DOWN);
        if Pressed(.ARROW_LEFT)  Move(.LEFT);
        if Pressed(.ARROW_RIGHT) Move(.RIGHT);
    }

    if Pressed("R") {
        InitTheGrid();
    }

    if Pressed(.MOUSE_BUTTON_RIGHT) {
        for * my_grid {
            r := GetTileRectangle(col_index, row_index);
            if Colliding(r, MousePositionOnApplication()) {
                if it.value > 2 {
                    it.value /= 2;
                } else {
                    it.* = {};
                }
            }
        }
    }

    if Pressed(.MOUSE_BUTTON_LEFT) {
        for * my_grid {
            r := GetTileRectangle(col_index, row_index);
            if Colliding(r, MousePositionOnApplication()) {
                if it.value > 0 {
                    it.value *= 2;
                } else {
                    it.value     = 2;
                    it.rectangle = r;
                    it.target    = r;
                }
            }
        }
    }
}

ApplicationUpdate :: (dt: float) {
    for * my_grid {
        if !it.value continue;
        Lerp(*it.color_lerp , 1.0        , 0.35);
        Lerp(*it.rectangle.x, it.target.x, 0.35);
        Lerp(*it.rectangle.y, it.target.y, 0.35);
        Lerp(*it.rectangle.w, it.target.w, 0.35);
        Lerp(*it.rectangle.h, it.target.h, 0.35);
    }

    for * my_grid {
        if it.spawning && it.color_lerp > 0.98 it.spawning = false;
    }

    if moving {
        finised_moving := true;
        for my_grid {
            if !it.value continue;
            if distance(Center(it.rectangle), Center(it.target)) > 5.0 finised_moving = false;
        }

        if finised_moving {
            moving = false;

            for * my_grid it.merging = false;

            if should_spawn_new_tile {
                SpawnRandomTile();
                should_spawn_new_tile = false;
            }
        }
    }
}

ApplicationRender :: () {
    for my_grid {
        rect := GetTileRectangle(col_index, row_index);
        PushColor(TILE_BG_COLOR);
        DrawRectangle(rect);
    }

    for my_grid {
        if !it.value continue;

        rect := it.rectangle;
        Resize(*rect, -10);

        rect_color := GetTileColor(it.value);
        text_color := GetTileTextColor(it.value);

        if it.spawning {
            Lerp(*rect_color, TILE_BG_COLOR, rect_color, it.color_lerp);
            Lerp(*text_color, TILE_BG_COLOR, text_color, it.color_lerp);
        } else if it.merging {
            old_rect_color := GetTileColor(it.value / 2);
            old_text_color := GetTileTextColor(it.value / 2);

            Lerp(*rect_color, old_rect_color, rect_color, it.color_lerp);
            Lerp(*text_color, old_text_color, text_color, it.color_lerp);
        }

        PushColor(rect_color);
        DrawRectangle(rect);

        PushColor(text_color);
        PushTranslation(Center(rect));
        PushAlignment(.CENTER);
        DrawText(my_font, tprint("%", it.value));
    }
}

my_font : *Font;
my_grid : Grid(GRID_SIZE, GRID_SIZE, Tile);

moving := false;

should_spawn_new_tile := false;

GRID_SIZE     :: 4;
TILE_MARGIN   :: 15.0;
TILE_SIZE     :: 150.0;
TILE_BG_COLOR :: #run Vector4.{ 205, 193, 180, 255 } / 255.0;

Tile :: struct {
    value       : int;
    rectangle   : Rectangle;
    target      : Rectangle;
    color_lerp  : float;
    merging     : bool;
    spawning    := true;
}

GetTileRectangle :: (y : int, x : int) -> Rectangle {
    size := GRID_SIZE * TILE_SIZE + (GRID_SIZE - 1) * TILE_MARGIN;
    rect := MakeRectangleFromCenter(ApplicationCenter(), size);
    return { L(rect) + x * (TILE_SIZE + TILE_MARGIN), T(rect) + y * (TILE_SIZE + TILE_MARGIN), TILE_SIZE, TILE_SIZE };
}

GetTileColor :: (value : int) -> Vector4 {
    if value == {
        case 2;   return { 238, 228, 218, 255 } / 255.0;
        case 4;   return { 237, 224, 200, 255 } / 255.0;
        case 8;   return { 242, 177, 121, 255 } / 255.0;
        case 16;  return { 245, 149, 99 , 255 } / 255.0;
        case 32;  return { 246, 124, 95 , 255 } / 255.0;
        case 64;  return { 246, 94 , 59 , 255 } / 255.0;
        case 128; return { 237, 207, 114, 255 } / 255.0;
        case;     return { 205, 193, 180, 255 } / 255.0;
    }
}

GetTileTextColor :: (value : int) -> Vector4 {
    return ifx value <= 4 then Vector4.{ 0, 0, 0, 1 } else .{ 1, 1, 1, 1 };
}

SpawnRandomTile :: () {
    empty_tiles := 0;
    for * my_grid if !it.value empty_tiles += 1;
    if !empty_tiles return;

    while true {
        c := RandomInt(my_grid.cols - 1);
        r := RandomInt(my_grid.rows - 1);

        if my_grid[c][r].value continue;

        my_grid[c][r].value    = ifx RandomFloat() > .9 then 4 else 2;
        my_grid[c][r].rectangle = GetTileRectangle(c, r);
        my_grid[c][r].target   = GetTileRectangle(c, r);

        return;
    }
}

InitTheGrid :: () {
    for * my_grid  it.* = {};
    SpawnRandomTile();
    SpawnRandomTile();
}

Move :: ($direction : enum { UP; DOWN; LEFT; RIGHT; }) {
    moving = true;

    for <=(direction == .DOWN), y : 0..my_grid.cols - 1 {
        for <=(direction == .RIGHT), x : 0..my_grid.rows - 1 {
            if !my_grid[y][x].value continue;

            dx := x;
            dy := y;

            while true {
                #if direction == .LEFT || direction == .RIGHT {
                    old_x := dx;
                    dx += ifx direction == .LEFT then -1 else +1;
                    if dx < 0 || dx > my_grid.rows - 1 break;
                    new_x := dx;

                    old := *my_grid[y][old_x];
                    new := *my_grid[y][new_x];

                    target := GetTileRectangle(y, new_x);
                } else {
                    old_y := dy;
                    dy += ifx direction == .UP then -1 else +1;
                    if dy < 0 || dy > my_grid.cols - 1 break;
                    new_y := dy;

                    old := *my_grid[old_y][x];
                    new := *my_grid[new_y][x];

                    target := GetTileRectangle(new_y, x);
                }

                if !new.value {
                    new.value    = old.value;
                    new.rectangle = old.rectangle;
                    new.target   = target;
                    old.value    = 0;

                    should_spawn_new_tile = true;
                } else if new.value == old.value && !old.merging && !new.merging {
                    new.value    = old.value * 2;
                    new.rectangle = BoundingBox(old.rectangle, new.rectangle);
                    new.target   = target;
                    new.merging  = true;
                    old.value    = 0;

                    should_spawn_new_tile = true;
                }
            }
        }
    }
}
