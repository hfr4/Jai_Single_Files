ApplicationTitle  :: "Cellular";
ApplicationWidth  :: 1400;
ApplicationHeight :: 900;

ApplicationInit :: () {
    
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Down(.MOUSE_BUTTON_LEFT) {
        mp := MousePositionOnApplication();
        x := cast(int) (mp.x / CELL_SIZE);
        y := cast(int) (mp.y / CELL_SIZE);
        PlaceCells(x, y, BRUSH_SIZE, selected);
    }

    if Pressed("1") selected = .SAND;
    if Pressed("2") selected = .WATER;
    if Pressed("3") selected = .STONE;
    if Pressed("4") selected = .NONE;
}

ApplicationUpdate :: (dt: float) {
    for < y : 0..my_grid.cols - 1 {
        for x : 0..my_grid.rows - 1 {

            if my_grid[y][x] == {
                case .SAND;
                    if y + 1 >= my_grid.cols continue;

                    if my_grid[y + 1][x] == {
                        case .NONE;
                            my_grid[y + 1][x] = .SAND;
                            my_grid[y]    [x] = .NONE;

                        case .WATER;
                            my_grid[y + 1][x] = .SAND;
                            my_grid[y]    [x] = .WATER;

                        case .SAND;
                            l := (x - 1 >= 0)           && (my_grid[y + 1][x - 1] == .NONE);
                            r := (x + 1 < my_grid.rows) && (my_grid[y + 1][x + 1] == .NONE);

                            if l && r {
                                v := ifx RandomBool() then -1 else 1;
                                my_grid[y + 1][x + v] = .SAND;
                                my_grid[y]    [x]     = .NONE;
                            } else if l {
                                my_grid[y + 1][x - 1] = .SAND;
                                my_grid[y]    [x]     = .NONE;
                            } else if r {
                                my_grid[y + 1][x + 1] = .SAND;
                                my_grid[y]    [x]     = .NONE;
                            }
                    }

                case .WATER;
                    if y + 1 < my_grid.cols && my_grid[y + 1][x] == .NONE {
                        my_grid[y + 1][x] = .WATER;
                        my_grid[y]    [x] = .NONE;
                    } else {
                        l := (x - 1 >= 0)           && (y + 1 < my_grid.cols) && (my_grid[y + 1][x - 1] == .NONE);
                        r := (x + 1 < my_grid.rows) && (y + 1 < my_grid.cols) && (my_grid[y + 1][x + 1] == .NONE);

                        if l && r {
                            v := ifx RandomBool() then -1 else 1;
                            my_grid[y + 1][x + v] = .WATER;
                            my_grid[y]    [x]     = .NONE;
                        } else if (l) {
                            my_grid[y + 1][x - 1] = .WATER;
                            my_grid[y]    [x]     = .NONE;
                        } else if (r) {
                            my_grid[y + 1][x + 1] = .WATER;
                            my_grid[y]    [x]     = .NONE;
                        } else {
                            lh := (x - 1 >= 0)           && (my_grid[y][x - 1] == .NONE);
                            rh := (x + 1 < my_grid.rows) && (my_grid[y][x + 1] == .NONE);

                            if lh && rh {
                                v := ifx RandomBool() then -1 else 1;
                                my_grid[y][x + v] = .WATER;
                                my_grid[y][x]     = .NONE;
                            } else if (lh) {
                                my_grid[y][x - 1] = .WATER;
                                my_grid[y][x]     = .NONE;
                            } else if (rh) {
                                my_grid[y][x + 1] = .WATER;
                                my_grid[y][x]     = .NONE;
                            }
                        }
                    }
            }
        }
    }
}

ApplicationRender :: () {
    for my_grid {
        if it == {
            case .SAND;   PushColor(.ORANGE); DrawRectangle({ xx (row_index * CELL_SIZE), xx (col_index * CELL_SIZE), xx CELL_SIZE, xx CELL_SIZE });
            case .WATER;  PushColor(.BLUE);   DrawRectangle({ xx (row_index * CELL_SIZE), xx (col_index * CELL_SIZE), xx CELL_SIZE, xx CELL_SIZE });
            case .STONE;  PushColor(.GREY);   DrawRectangle({ xx (row_index * CELL_SIZE), xx (col_index * CELL_SIZE), xx CELL_SIZE, xx CELL_SIZE });
        }
    }
}

PlaceCells :: (cx: int, cy: int, size: int, kind: Cell_Kind) {
    half := size / 2;
    for dx : -half..half - 1 {
        for dy : -half..half - 1 {
            col := cy + dy;
            row := cx + dx;
            if Contains(my_grid, col, row) my_grid[col][row] = kind;
        }
    }
}

my_grid  : Grid(ApplicationHeight / CELL_SIZE, ApplicationWidth / CELL_SIZE, Cell_Kind);
selected : Cell_Kind = .SAND;

CELL_SIZE   :: 4;
BRUSH_SIZE  :: 4;

Cell_Kind :: enum {
    NONE;
    SAND;
    WATER;
    STONE;
}