ApplicationTitle  :: "Quadtree";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {
    for 0..10 {
        rectangle := New(Shape_Rectangle);

        x := random_get_within_range(200.0, ApplicationRectangle().w - 200.0);
        y := random_get_within_range(200.0, ApplicationRectangle().h - 200.0);
        rectangle.position  = .{ x, y };
        rectangle.direction = normalize(Vector2.{ random_get_within_range(-1.0, 1.0), random_get_within_range(-1.0, 1.0) });
        rectangle.width     = 50.0;
        rectangle.height    = 50.0;

        array_add(*my_shapes, rectangle);
    }

    for 0..10 {
        circle  := New(Shape_Circle);

        x := random_get_within_range(100.0, ApplicationRectangle().w - 100.0);
        y := random_get_within_range(100.0, ApplicationRectangle().h - 100.0);
        circle.position  = .{ x, y };
        circle.direction = normalize(Vector2.{ random_get_within_range(-1.0, 1.0), random_get_within_range(-1.0, 1.0) });
        circle.radius    = 30.0;

        array_add(*my_shapes, circle);
    }
}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        mp := MousePositionOnApplication();

        circle := New(Shape_Circle);
        circle.position  = mp;
        circle.direction = normalize(Vector2.{ random_get_within_range(-1.0, 1.0), random_get_within_range(-1.0, 1.0) });
        circle.radius    = 30.0;

        array_add(*my_shapes, circle);
    }
}

ApplicationUpdate :: (dt: float) {
    for my_shapes {
        it.position += it.direction * 50.0 * dt;

        if it.position.x < 100 || it.position.x > ApplicationRectangle().w - 100  it.direction.x *= -1;
        if it.position.y < 100 || it.position.y > ApplicationRectangle().h - 100  it.direction.y *= -1;
    }
}

ApplicationRender :: () {
    colliders: [..] Collider;
    colliders.allocator = temp;

    for my_shapes {
        collider := array_add(*colliders);
        collider.data = it;

        if it.kind == {
            case .RECTANGLE;
                rectangle := cast(*Shape_Rectangle) it;
                collider.aabb.min = rectangle.position;
                collider.aabb.max = .{ rectangle.position.x + rectangle.width, rectangle.position.y + rectangle.height };

            case .CIRCLE;
                circle := cast(*Shape_Circle) it;
                collider.aabb.min = circle.position - Vector2.{ circle.radius, circle.radius };
                collider.aabb.max = circle.position + Vector2.{ circle.radius, circle.radius };
        }
    }

    quadtree: Quadtree(4, 4);
    Insert(*quadtree, colliders);
    defer Deinit(*quadtree);

    for quadtree.nodes {
        PushMode(.LINE);
        PushColor(.RED);
        DrawRectangle(BoundingBox(it.aabb.min, it.aabb.max));
    }

    for quadtree.nodes {
        for it.colliders {
            PushMode(.LINE);
            PushColor(.GREEN);
            DrawRectangle(BoundingBox(it.aabb.min, it.aabb.max));
        }
    }

    for my_shapes {
        if it.kind == {
            case .RECTANGLE;
                rectangle := cast(*Shape_Rectangle) it;
                r := Rectangle.{ rectangle.position.x, rectangle.position.y, rectangle.width, rectangle.height };
                PushColor(0, 1, 1);
                DrawRectangle(r);

            case .CIRCLE;
                circle := cast(*Shape_Circle) it;
                c := Circle.{ circle.position.x, circle.position.y, circle.radius };
                PushColor(0, 1, 1);
                DrawCircle(c);
        }
    }

    collisions := GetCollisions(quadtree);
    collisions.allocator = temp;
    for collisions {
        PushColor(1, 1, 0);
        DrawRectangle(BoundingBox(it.a.aabb.min, it.a.aabb.max));
        PushColor(1, 1, 0);
        DrawRectangle(BoundingBox(it.b.aabb.min, it.b.aabb.max));
    }
}

Shape_Kind :: enum {
    CIRCLE;
    RECTANGLE;
}

Shape :: struct {
    kind      : Shape_Kind;
    direction : Vector2;
    position  : Vector2;
}

Shape_Rectangle :: struct {
    using #as base: Shape;
    kind = .RECTANGLE;
    width  :  float;
    height : float;
}

Shape_Circle :: struct {
    using #as base: Shape;
    kind = .CIRCLE;
    radius: float;
}

my_shapes: [..] *Shape;

Quadtree :: struct(max_depth : int, capacity_per_node : int) {
    capacity :: #run cast(int) (pow(cast(float) capacity_per_node, cast(float) max_depth) + 1.0);
    nodes : [capacity] Node;
    count := 0;
}

Node :: struct {
    aabb      : AABB;
    children  : [4] int;
    is_leaf   := true;
    colliders : [..] Collider;
}

AABB :: struct {
    min, max: Vector2;
}

Collider :: struct {
    aabb : AABB;
    data : *void;
}

Collision :: struct {
    a, b : Collider;
}

Insert :: (using tree: *Quadtree, colliders : [] Collider) {
    if tree.nodes.count == 0 {
        Init(tree, colliders);
        return;
    }

    // Rebuild the entire tree if the root node doesn't contain all colliders
    for colliders {
        if !Contains(nodes[0].aabb, it.aabb) {
            colls: [..] Collider;
            colls.allocator = temp;

            for nodes array_add(*colls, ..it.colliders);
            array_add(*colls, ..colliders);

            Deinit(tree);
            Init(tree, colls);
            return;
        }
    }

    for colliders Insert(tree, 0, it, 0);
}

GetCollisions :: (quadtree: Quadtree) -> [..] Collision {
    collisions: [..] Collision;
    GetNodeCollisions(quadtree, 0, *collisions);
    return collisions;
}

Deinit :: (using tree: *Quadtree) {
    for nodes array_reset(*it.colliders);
    count = 0;
}

Init :: (using tree: *Quadtree, colliders: [] Collider) {
    root := *tree.nodes[0];
    root.aabb = colliders[0].aabb;
    for colliders {
        root.aabb.min = min(root.aabb.min, it.aabb.min);
        root.aabb.max = max(root.aabb.max, it.aabb.max);
    }
    root.aabb.min -= { 1, 1 };
    root.aabb.max += { 1, 1 };

    tree.count = 1;

    for colliders Insert(tree, 0, it, 0);
}

Insert :: (using tree: *Quadtree, i: int, collider: Collider, depth: int) {
    using node := *nodes[i];

    if !is_leaf {
        if      Contains(nodes[children[0]].aabb, collider.aabb) Insert(tree, children[0], collider, depth + 1);
        else if Contains(nodes[children[1]].aabb, collider.aabb) Insert(tree, children[1], collider, depth + 1);
        else if Contains(nodes[children[2]].aabb, collider.aabb) Insert(tree, children[2], collider, depth + 1);
        else if Contains(nodes[children[3]].aabb, collider.aabb) Insert(tree, children[3], collider, depth + 1);
        else                                                     array_add(*colliders, collider);
    } else {
        array_add(*colliders, collider);

        if colliders.count > capacity_per_node && depth < max_depth {
            is_leaf = false;

            children[0] = count + 0;
            children[1] = count + 1;
            children[2] = count + 2;
            children[3] = count + 3;

            count += 4;

            node0 := *tree.nodes[children[0]];
            node1 := *tree.nodes[children[1]];
            node2 := *tree.nodes[children[2]];
            node3 := *tree.nodes[children[3]];

            half_size := (aabb.max - aabb.min) / 2.0;
            center    := (aabb.min + aabb.max) / 2.0;

            p0 := Vector2.{ aabb.min.x, aabb.min.y };
            p1 := Vector2.{ aabb.min.x, center.y   };
            p2 := Vector2.{ center.x  , aabb.min.y };
            p3 := Vector2.{ center.x  , center.y   };

            node0.aabb = { p0, p0 + half_size };
            node1.aabb = { p1, p1 + half_size };
            node2.aabb = { p2, p2 + half_size };
            node3.aabb = { p3, p3 + half_size };

            for colliders {
                if      Contains(nodes[children[0]].aabb, it.aabb) { Insert(tree, children[0], it, depth + 1); remove it; }
                else if Contains(nodes[children[1]].aabb, it.aabb) { Insert(tree, children[1], it, depth + 1); remove it; }
                else if Contains(nodes[children[2]].aabb, it.aabb) { Insert(tree, children[2], it, depth + 1); remove it; }
                else if Contains(nodes[children[3]].aabb, it.aabb) { Insert(tree, children[3], it, depth + 1); remove it; }
            }
        }
    }
}

GetNodeCollisions :: (using tree: Quadtree, i: int, collisions: *[..] Collision) {
    if nodes.count == 0 return;

    using node := *nodes[i];

    for i : 0..colliders.count - 2 {
        for j : i + 1..colliders.count - 1 {
            if Colliding(colliders[i].aabb, colliders[j].aabb) {
                array_add(collisions, .{ colliders[i], colliders[j] });
            }
        }
    }

    if !is_leaf {
        GetNodeCollisions(tree, children[0], collisions);
        GetNodeCollisions(tree, children[1], collisions);
        GetNodeCollisions(tree, children[2], collisions);
        GetNodeCollisions(tree, children[3], collisions);

        for colliders {
            GetChildrenCollisions(tree, children[0], it, collisions);
            GetChildrenCollisions(tree, children[1], it, collisions);
            GetChildrenCollisions(tree, children[2], it, collisions);
            GetChildrenCollisions(tree, children[3], it, collisions);
        }
    }
}

GetChildrenCollisions :: (using tree: Quadtree, i: int, collider: Collider, collisions: *[..] Collision) {
    using node := *nodes[i];

    for other : colliders {
        if Colliding(collider.aabb, other.aabb) {
            array_add(collisions, .{ collider, other });
        }
    }

    if !is_leaf {
        GetChildrenCollisions(tree, children[0], collider, collisions);
        GetChildrenCollisions(tree, children[1], collider, collisions);
        GetChildrenCollisions(tree, children[2], collider, collisions);
        GetChildrenCollisions(tree, children[3], collider, collisions);
    }
}

Colliding :: (a: AABB, b: AABB) -> bool {
    return !(
        a.max.x < b.min.x || b.max.x < a.min.x ||
        a.max.y < b.min.y || b.max.y < a.min.y
    );
}

Contains :: (a: AABB, b: AABB) -> bool {
    return !(
        a.min.x > b.min.x || a.max.x <= b.max.x ||
        a.min.y > b.min.y || a.max.y <= b.max.y
    );
}