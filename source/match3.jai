ApplicationTitle  :: "Match3";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    garnet_texture  = LoadTexture("assets/match3/garnet.png");
    topaz_texture   = LoadTexture("assets/match3/topaz.png");
    citrine_texture = LoadTexture("assets/match3/citrine.png");
    emerald_texture = LoadTexture("assets/match3/emerald.png");
}

ApplicationReset :: () {
    ChangeRandomSeed();
    ChangeEvent(.NONE);
    InitializeGrid();
}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed("R") Reset();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        ok, col, row := GemUnderMousePointer();

        if ok {
            if event_state == .NONE {
                select_data.gem = { col, row };
                ChangeEvent(.SELECT);
            } else if event_state == .SELECT {
                c1 := select_data.gem.col;
                r1 := select_data.gem.row;

                c2 := col;
                r2 := row;

                is_adjacent := abs(r1 - r2) + abs(c1 - c2) == 1;

                if is_adjacent {
                    a := At(*the_grid, c1, r1);
                    b := At(*the_grid, c2, r2);
                    swap(*a.kind, *b.kind);
                    swap_data.gems = .[ { c1, r1 }, { c2, r2 } ];

                    ChangeEvent(.SWAP);
                } else {
                    ChangeEvent(.NONE);
                }
            }
        }
    }
}

ApplicationUpdate :: (dt: float) {
    event_elapsed += dt;

    if event_elapsed > event_lifetime {
        if event_state == {
            case .SWAP;
                matches := FindMatches();
                if matches.count > 0 {
                    array_add(*delete_data.gems, ..matches);
                    ChangeEvent(.DELETE);
                } else {
                    a := At(*the_grid, swap_data.gems[0].col, swap_data.gems[0].row);
                    b := At(*the_grid, swap_data.gems[1].col, swap_data.gems[1].row);
                    swap(*a.kind, *b.kind);
                    unswap_data.gems = .[ swap_data.gems[1], swap_data.gems[0] ];
                    ChangeEvent(.UNSWAP);
                }

            case .UNSWAP;
                ChangeEvent(.NONE);

            case .FALL;
                matches := FindMatches();
                if matches.count > 0 {
                    array_add(*delete_data.gems, ..matches);
                    ChangeEvent(.DELETE);
                } else {
                    ChangeEvent(.NONE);
                }
                array_reset(*fall_data.gems);

            case .DELETE;
                for < gem : the_grid {
                    for delete_data.gems if it == .{ col_index, row_index } continue gem;

                    deleted_blocks_bellow := 0;
                    for delete_data.gems if it.col > col_index && it.row == row_index  deleted_blocks_bellow += 1;
                    if !deleted_blocks_bellow continue;

                    a := At(*the_grid, col_index, row_index);
                    b := At(*the_grid, col_index + deleted_blocks_bellow, row_index);
                    swap(*a.kind, *b.kind);

                    from := Gem_Position.{ col_index, row_index };
                    to   := Gem_Position.{ col_index + deleted_blocks_bellow, row_index };
                    array_add(*fall_data.gems, { from, to });
                }

                for row : 0..the_grid.rows - 1 {
                    deleted_blocks_in_this_col := 0;
                    for delete_data.gems if it.row == row  deleted_blocks_in_this_col += 1;
                    if !deleted_blocks_in_this_col continue;

                    for 0..deleted_blocks_in_this_col - 1 {
                        created := At(*the_grid, it, row);
                        created.* = CreateGem();

                        from := Gem_Position.{ it - deleted_blocks_in_this_col, row };
                        to   := Gem_Position.{ it , row };
                        array_add(*fall_data.gems, { from, to });
                    }
                }

                ChangeEvent(.FALL);
                array_reset(*delete_data.gems);
        }
    }
}

ApplicationRender :: () {
    {
        PushRGB(0x111111);
        DrawRectangle(ApplicationRectangle());
    }

    for gem : the_grid {
        if event_state == {
            case .SWAP;
                for swap_data.gems   if it      == .{ col_index, row_index } continue gem;

            case .UNSWAP;
                for unswap_data.gems if it      == .{ col_index, row_index } continue gem;

            case .FALL;
                for fall_data.gems   if it.from == .{ col_index, row_index } continue gem;
                for fall_data.gems   if it.to   == .{ col_index, row_index } continue gem;

            case .DELETE;
                for delete_data.gems if it      == .{ col_index, row_index } continue gem;
        }

        rect := GemRectangle(col_index, row_index);
        if gem.kind == {
            case .GARNET;  DrawTexture(garnet_texture , rect);
            case .TOPAZ;   DrawTexture(topaz_texture  , rect);
            case .CITRINE; DrawTexture(citrine_texture, rect);
            case .EMERALD; DrawTexture(emerald_texture, rect);
        }
    }

    if event_state ==  {
        case .SELECT;
            percent := event_elapsed / event_lifetime;
            Clamp(*percent, 0, 1);

            PushAlpha(percent);
            PushMode(.LINE);
            PushWidth(3.0);
            DrawRectangle(GemRectangle(select_data.gem.col, select_data.gem.row));

        case .SWAP;
            percent := event_elapsed / event_lifetime;
            Clamp(*percent, 0, 1);

            using swap_data;

            gem2 := At(*the_grid, gems[0].col, gems[0].row);
            gem1 := At(*the_grid, gems[1].col, gems[1].row);

            rect1 := GemRectangle(gems[0].col, gems[0].row);
            rect2 := GemRectangle(gems[1].col, gems[1].row);

            center1 := lerp(Center(rect1), Center(rect2), InOutQuad(percent));
            center2 := lerp(Center(rect2), Center(rect1), InOutQuad(percent));

            SetCenter(*rect1, center1);
            SetCenter(*rect2, center2);

            margin1 := lerp(0, +15, Yoyo(InOutQuad, percent));
            margin2 := lerp(0, -15, Yoyo(InOutQuad, percent));

            Resize(*rect1, margin1);
            Resize(*rect2, margin2);

            if gem2.kind == {
                case .GARNET;  DrawTexture(garnet_texture , rect2);
                case .TOPAZ;   DrawTexture(topaz_texture  , rect2);
                case .CITRINE; DrawTexture(citrine_texture, rect2);
                case .EMERALD; DrawTexture(emerald_texture, rect2);
            }

            if gem1.kind == {
                case .GARNET;  DrawTexture(garnet_texture , rect1);
                case .TOPAZ;   DrawTexture(topaz_texture  , rect1);
                case .CITRINE; DrawTexture(citrine_texture, rect1);
                case .EMERALD; DrawTexture(emerald_texture, rect1);
            }

        case .UNSWAP;
            percent := event_elapsed / event_lifetime;
            Clamp(*percent, 0, 1);

            using unswap_data;

            gem2 := At(*the_grid, gems[0].col, gems[0].row);
            gem1 := At(*the_grid, gems[1].col, gems[1].row);

            rect1 := GemRectangle(gems[0].col, gems[0].row);
            rect2 := GemRectangle(gems[1].col, gems[1].row);

            center1 := lerp(Center(rect1), Center(rect2), InOutQuad(percent));
            center2 := lerp(Center(rect2), Center(rect1), InOutQuad(percent));

            SetCenter(*rect1, center1);
            SetCenter(*rect2, center2);

            margin1 := lerp(0, +15, Yoyo(InOutQuad, percent));
            margin2 := lerp(0, -15, Yoyo(InOutQuad, percent));

            Resize(*rect1, margin1);
            Resize(*rect2, margin2);

            if gem2.kind == {
                case .GARNET;  DrawTexture(garnet_texture , rect2);
                case .TOPAZ;   DrawTexture(topaz_texture  , rect2);
                case .CITRINE; DrawTexture(citrine_texture, rect2);
                case .EMERALD; DrawTexture(emerald_texture, rect2);
            }

            if gem1.kind == {
                case .GARNET;  DrawTexture(garnet_texture , rect1);
                case .TOPAZ;   DrawTexture(topaz_texture  , rect1);
                case .CITRINE; DrawTexture(citrine_texture, rect1);
                case .EMERALD; DrawTexture(emerald_texture, rect1);
            }


        case .DELETE;
            percent := event_elapsed / event_lifetime;
            Clamp(*percent, 0, 1);

            for delete_data.gems {
                gem := At(*the_grid, it.col, it.row);
                rect := GemRectangle(it.col, it.row);

                alpha := lerp(1.0, 0.0, percent);

                PushAlpha(alpha);
                if gem.kind == {
                    case .GARNET;  DrawTexture(garnet_texture , rect);
                    case .TOPAZ;   DrawTexture(topaz_texture  , rect);
                    case .CITRINE; DrawTexture(citrine_texture, rect);
                    case .EMERALD; DrawTexture(emerald_texture, rect);
                }
            }


        case .FALL;
            percent := event_elapsed / event_lifetime;
            Clamp(*percent, 0, 1);

            for fall_data.gems {
                rect1 := GemRectangle(it.from.col, it.from.row);
                rect2 := GemRectangle(it.to.col , it.to.row);

                center := lerp(Center(rect1), Center(rect2), percent);
                SetCenter(*rect1, center);

                gem := At(*the_grid, it.to.col, it.to.row);
                if gem.kind == {
                    case .GARNET;  DrawTexture(garnet_texture , rect1);
                    case .TOPAZ;   DrawTexture(topaz_texture  , rect1);
                    case .CITRINE; DrawTexture(citrine_texture, rect1);
                    case .EMERALD; DrawTexture(emerald_texture, rect1);
                }
            }
    }
}


InitializeGrid :: () {
    while true {
        for * the_grid it.* = CreateGem();
        matches := FindMatches();
        if !matches.count break;
    }
}

CreateGem :: () -> Gem {
    return { RandomEnumValue(Gem_Kind) };
}

GridRectangle :: () -> Rectangle {
    w := the_grid.rows * GEM_SIZE;
    h := the_grid.cols * GEM_SIZE;
    return MakeRectangleFromCenter(ApplicationCenter(), { xx w, xx h });
}

GemRectangle :: (col: int, row: int) -> Rectangle {
    r := GridRectangle();
    x := row * GEM_SIZE;
    y := col * GEM_SIZE;
    return { L(r) + x, T(r) + y, xx GEM_SIZE, xx GEM_SIZE };
}

GemUnderMousePointer :: () -> bool, int, int {
    p := MousePositionOnApplication() - TL(GridRectangle());

    col := cast(int) (floor(p.y / GEM_SIZE));
    row := cast(int) (floor(p.x / GEM_SIZE));

    return Contains(the_grid, col, row), col, row;
}

FindMatches :: () -> [..] Gem_Position {
    matches : [..] Gem_Position;
    matches.allocator = temp;

    find :: (array: [] $T, item: T) -> bool, s64 {
        for array if it == item return true, it_index;
        return false, -1;
    }

    add_if_unique :: (array: *[..] $T, item: T) -> bool, s64 {
        found, index := find(array.*, item);
        if found return false, index;
        array_add(array, item);
        return true, array.count-1;
    }

    for col : 0..the_grid.cols - 1 {
        for row : 0..the_grid.rows - 3 {
            a := the_grid[col][row + 0];
            b := the_grid[col][row + 1];
            c := the_grid[col][row + 2];

            if a.kind == b.kind && b.kind == c.kind {
                add_if_unique(*matches, Gem_Position.{ col, row + 0 });
                add_if_unique(*matches, Gem_Position.{ col, row + 1 });
                add_if_unique(*matches, Gem_Position.{ col, row + 2 });
            }
        }
    }

    for row : 0..the_grid.rows - 1 {
        for col : 0..the_grid.cols - 3 {
            a := the_grid[col + 0][row];
            b := the_grid[col + 1][row];
            c := the_grid[col + 2][row];

            if a.kind == b.kind && b.kind == c.kind {
                add_if_unique(*matches, Gem_Position.{ col + 0, row });
                add_if_unique(*matches, Gem_Position.{ col + 1, row });
                add_if_unique(*matches, Gem_Position.{ col + 2, row });
            }
        }
    }

    return matches;
}

ChangeEvent :: (event: Event_State) {
    swap_lifetime    :: 0.4;
    unswap_lifetime  :: 0.4;
    delete_lifetime  :: 0.5;
    fall_lifetime    :: 0.6;
    select_lifetime  :: 0.2;

    if event == {
        case .NONE;   event_lifetime = 0.0;
        case .SELECT; event_lifetime = select_lifetime;
        case .SWAP;   event_lifetime = swap_lifetime;
        case .UNSWAP; event_lifetime = unswap_lifetime;
        case .FALL;   event_lifetime = fall_lifetime;
        case .DELETE; event_lifetime = delete_lifetime;
    }
    event_elapsed = 0.0;
    event_state = event;
}

GEM_SIZE :: 50;

the_grid : Grid(10, 7, Gem);

event_state    : Event_State;
event_elapsed  := 0.0;
event_lifetime := 0.0;

garnet_texture  : Texture;
topaz_texture   : Texture;
citrine_texture : Texture;
emerald_texture : Texture;

select_data : struct {
    gem : Gem_Position;
}

swap_data : struct {
    gems : [2] Gem_Position;
}

unswap_data : struct {
    gems : [2] Gem_Position;
}

delete_data : struct {
    gems : [..] Gem_Position;
}

fall_data : struct {
    Falling_Gem :: struct {
        from, to : Gem_Position;
    }
    gems : [..] Falling_Gem;
}

Event_State :: enum {
    NONE;
    SELECT;
    SWAP;
    UNSWAP;
    FALL;
    DELETE;
}

Gem_Kind :: enum {
    GARNET;
    TOPAZ;
    CITRINE;
    EMERALD;
}

Gem :: struct {
    kind : Gem_Kind;
}

Gem_Position :: struct {
    col, row : int;
}

operator == :: (a: Gem_Position, b: Gem_Position) -> bool {
    return a.col == b.col && a.row == b.row;
}