ApplicationTitle  :: "Tree";
ApplicationWidth  :: 900;
ApplicationHeight :: 900;

ApplicationInit :: () {

}

ApplicationReset :: () {

}

ApplicationEvents :: () {
    if Pressed(.ESCAPE) Quit();

    mp := MousePositionOnApplication();

    if Pressed(.MOUSE_BUTTON_LEFT) {
        ent : Userdata;
        ent.circle = { mp.x, mp.y, 30 };
        loc, ptr := bucket_array_add(*entities, ent);
        Insert(*tree, ptr, MakeAABB(ent.circle));
    }

    if Pressed(.MOUSE_BUTTON_RIGHT) {
        for entities {
            if Colliding(it.circle, mp) {
                Remove(*tree, it.node);
                break;
            }
        }
    }
}

ApplicationUpdate :: (dt: float) {
    
}

ApplicationRender :: () {
    RenderNode :: (node: *Node) {
        if !node return;

        r := BoundingBox({ node.aabb.min.x, node.aabb.min.y }, { node.aabb.max.x, node.aabb.max.y });
        color : Vector4;
        if node.depth == {
            case 0; color = { 1., 1., 1., 1. };
            case 1; color = { .8, .8, .8, .8 };
            case 2; color = { .6, .6, .6, .6 };
            case 3; color = { .4, .4, .4, .4 };
            case;   color = { .2, .2, .2, .2 };
        }

        PushMode(.LINE);
        PushWidth(2);
        PushColor(color);
        DrawRectangle(r);

        if node.userdata {
            PushMode(.LINE);
            PushWidth(2);
            PushColor(.RED);
            DrawCircle(node.userdata.circle);
        }

        RenderNode(node.left);
        RenderNode(node.right);
    }

    RenderNode(tree.root);
}

entities : Bucket_Array(Userdata, 64);
tree     : Tree;

Userdata :: struct {
    circle : Circle;
    node   : *Node;
}

AABB :: struct {
    min, max : Vector2;
}

MakeAABB :: (c: Circle) -> AABB {
    bb := BoundingBox(c);
    return { TL(bb), BR(bb) };
}

MakeFatAABB :: (using aabb: AABB, margin: int) -> AABB {
    return {
        { min.x - margin, min.y - margin },
        { max.x + margin, max.y + margin },
    };
}

Combine :: (A: AABB, B: AABB) -> AABB {
    return {
        { min(A.min.x, B.min.x), min(A.min.y, B.min.y) },
        { max(A.max.x, B.max.x), max(A.max.y, B.max.y) },
    };
}

Perimeter :: (using aabb: AABB) -> float {
    return 2 * (max.x - min.x + max.y - min.y);
}

Contains :: (A: AABB, B: AABB) -> bool {
    return A.min.x <= B.min.x && A.min.y <= B.min.y && A.max.x >= B.max.x && A.max.y >= B.max.y;
}

Node :: struct {
    aabb     : AABB;
    parent   : *Node;
    left     : *Node;
    right    : *Node;
    depth    : int;

    userdata : *Userdata;
}

IsLeaf :: (using node: Node) -> bool {
    return left == null;
}

Tree :: struct {
    root   : *Node;
    margin : int = 20;
}

Insert :: (using tree: *Tree, entity: *Userdata, aabb: AABB) -> *Node {
    fat_aabb := MakeFatAABB(aabb, margin);

    node := New(Node);
    node.aabb     = fat_aabb;
    node.userdata = entity;

    entity.node = node; // Link back for updates

    if !tree.root {
        tree.root = node;
        return node;
    }

    leaf := tree.root;

    while !IsLeaf(leaf) {
        combined         := Perimeter(Combine(leaf.aabb, fat_aabb));
        cost             := 2 * combined;
        inheritance_cost := 2 * (combined - Perimeter(leaf.aabb));

        cost_left: float;
        if IsLeaf(leaf.left) {
            cost_left = Perimeter(Combine(leaf.left.aabb, fat_aabb)) + inheritance_cost;
        } else {
            old := Perimeter(leaf.left.aabb);
            new := Perimeter(Combine(leaf.left.aabb, fat_aabb));
            cost_left = (new - old) + inheritance_cost;
        }

        cost_right : float;
        if IsLeaf(leaf.right) {
            cost_right = Perimeter(Combine(leaf.right.aabb, fat_aabb)) + inheritance_cost;
        } else {
            old := Perimeter(leaf.right.aabb);
            new := Perimeter(Combine(leaf.right.aabb, fat_aabb));
            cost_right = (new - old) + inheritance_cost;
        }

        if cost < cost_left && cost < cost_right break;

        leaf = ifx cost_left < cost_right then leaf.left else leaf.right;
    }

    old_parent := leaf.parent;

    new_parent := New(Node);
    new_parent.aabb   = Combine(leaf.aabb, fat_aabb);
    new_parent.parent = old_parent;

    if old_parent {
        if old_parent.left == leaf old_parent.left  = new_parent;
        else                       old_parent.right = new_parent;
    } else {
        tree.root = new_parent;
    }

    new_parent.left  = leaf;
    new_parent.right = node;
    leaf.parent     = new_parent;
    node.parent     = new_parent;

    BalanceHierarchy(tree, new_parent);

    return node;
}

Remove :: (using tree: *Tree, node: *Node) {
    if !node return;

    if node == tree.root {
        tree.root = null;
        return;
    }

    parent      := node.parent;
    grand_parent := parent.parent;
    sibling     := ifx parent.left == node then parent.right else parent.left;

    if grand_parent {
        if grand_parent.left == parent grand_parent.left  = sibling;
        else                           grand_parent.right = sibling;
        sibling.parent = grand_parent;
        BalanceHierarchy(tree, grand_parent);
    } else {
        tree.root = sibling;
        sibling.parent = null;
    }
}

Update :: (using tree: *Tree, entity: *Userdata, aabb: AABB) -> bool {
    node := entity.node;

    // Only re-insert if the object has moved outside its "fat" box
    if Contains(node.aabb, aabb) return false;

    Remove(tree, node);
    Insert(tree, entity, aabb);

    return true;
}

Clear :: (using tree: *Tree) {
    tree.root = null;
}

Count :: (using tree: Tree) -> int {
    Traverse :: (node: *Node, count: *int) {
        if !node return;
        count.* += 1;
        Traverse(node.left, count);
        Traverse(node.right, count);
    }

    count := 0;
    Traverse(tree.root, *count);
    return count;
}

BalanceHierarchy :: (using tree: *Tree, n: *Node) {
    Balance :: (using tree: *Tree, n: *Node) -> *Node {
        if IsLeaf(n) || n.depth < 2 return n;

        l := n.left;
        r := n.right;

        balance := r.depth - l.depth;

        if balance > 1 {
            rl := r.left;
            rr := r.right;

            r.left   = n;
            r.parent = n.parent;

            n.parent = r;

            if r.parent {
                if r.parent.left == n r.parent.left  = r;
                else                  r.parent.right = r;
            } else {
                tree.root = r;
            }

            if rl.depth > rr.depth {
                r.right = rl;
                n.right = rr;

                rr.parent = n;

                n.aabb = Combine(l.aabb, rr.aabb);
                r.aabb = Combine(n.aabb, rl.aabb);

                n.depth = 1 + max(l.depth, rr.depth);
                r.depth = 1 + max(n.depth, rl.depth);
            } else {
                r.right = rr;
                n.right = rl;

                rl.parent = n;

                n.aabb = Combine(l.aabb, rl.aabb);
                r.aabb = Combine(n.aabb, rr.aabb);

                n.depth = 1 + max(l.depth, rl.depth);
                r.depth = 1 + max(n.depth, rr.depth);
            }

            return r;
        } else if balance < -1 {
            ll := l.left;
            lr := l.right;

            l.left   = n;
            l.parent = n.parent;

            n.parent = l;

            if l.parent {
                if l.parent.left == n l.parent.left  = l;
                else                  l.parent.right = l;
            } else {
                tree.root = l;
            }

            if ll.depth > lr.depth {
                l.right = ll;
                n.left  = lr;

                lr.parent = n;

                n.aabb = Combine(r.aabb, lr.aabb);
                l.aabb = Combine(n.aabb, ll.aabb);

                n.depth = 1 + max(r.depth, lr.depth);
                l.depth = 1 + max(n.depth, ll.depth);
            } else {
                l.right = lr;
                n.left  = ll;

                ll.parent = n;

                n.aabb = Combine(r.aabb, ll.aabb);
                l.aabb = Combine(n.aabb, lr.aabb);

                n.depth = 1 + max(r.depth, ll.depth);
                l.depth = 1 + max(n.depth, lr.depth);
            }

            return l;
        } else {
            return n;
        }
    }

    while n {
        n = Balance(tree, n);

        l := n.left;
        r := n.right;

        n.depth = 1 + max(l.depth, r.depth);
        n.aabb  = Combine(l.aabb, r.aabb);

        n = n.parent;
    }
}

#import "Bucket_Array";