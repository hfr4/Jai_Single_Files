Rectangle :: struct {
    x, y, w, h : float;
}

MakeRectangle :: (position: Vector2, size: Vector2) -> Rectangle {
    return { position.x, position.y, size.x, size.y };
}

MakeRectangle :: (position: Vector2, size: float) -> Rectangle {
    return { position.x, position.y, size, size };
}

MakeRectangleFromCenter :: (center: Vector2, size: Vector2) -> Rectangle {
    tl := center - size/2;
    br := center + size/2;
    return BoundingBox(tl, br);
}

MakeRectangleFromCenter :: (center: Vector2, size: float) -> Rectangle {
    return MakeRectangleFromCenter(center, { size, size });
}

MinkowskiDif :: (a: Rectangle, b: Rectangle) -> Rectangle {
    return { L(b) - R(a), T(b) - B(a), a.w + b.w, a.h + b.h };
}

BoundingBox :: (a: Vector2, b: Vector2) -> Rectangle {
    x := min(a.x, b.x);
    y := min(a.y, b.y);
    w := max(a.x, b.x) - x;
    h := max(a.y, b.y) - y;
    return { x, y, w, h };
}

BoundingBox :: (points: [] Vector2) -> Rectangle {
    l, t := +FLOAT32_MAX;
    r, b := -FLOAT32_MAX;
    for points {
        l = min(l, it.x);
        t = min(t, it.y);
        r = max(r, it.x);
        b = max(b, it.y);
    }
    return BoundingBox({ l, t }, { r, b });
}

BoundingBox :: (using c: Circle) -> Rectangle {
    return MakeRectangleFromCenter({ x, y }, r * 2);
}

BoundingBox :: (using s: Segment) -> Rectangle {
    return BoundingBox(a, b);
}

BoundingBox :: (using p: Polygon) -> Rectangle {
    return BoundingBox(points);
}

BoundingBox :: (using e: Ellipse) -> Rectangle {
    return MakeRectangleFromCenter({ x, y }, { w, h } * 2);
}

BoundingBox :: (using rs: Rounded_Segment) -> Rectangle {
    bb := BoundingBox(rs.segment);
    Resize(*bb, r * 2);
    return bb;
}

BoundingBox :: (using rr: Rounded_Rectangle) -> Rectangle {
    bb := rr.rectangle;
    Resize(*bb, r * 2);
    return bb;
}

BoundingBox :: (using rp: Rounded_Polygon) -> Rectangle {
    bb := BoundingBox(rp.polygon);
    Resize(*bb, r * 2);
    return bb;
}

BoundingBox :: (a: Rectangle, b: Vector2) -> Rectangle #symmetric {
    return BoundingBox(Vector2.[ TL(a), BR(a), b ]);
}

BoundingBox :: (a: Rectangle, b: Rectangle) -> Rectangle {
    tl := Vector2.{ min(L(a), L(b)), min(T(a), T(b)) };
    br := Vector2.{ max(R(a), R(b)), max(B(a), B(b)) };
    return BoundingBox(tl, br);
}

BoundingBox :: (rectangles: [] Rectangle) -> Rectangle {
    result := rectangles[0];
    for rectangles result = BoundingBox(result, it);
    return result;
}

Intersection :: (a: Rectangle, b: Rectangle) -> bool, Rectangle {
    if !Colliding(a, b) return false, {};
    tl := Vector2.{ max(L(a), L(b)), max(T(a), T(b)) };
    br := Vector2.{ min(R(a), R(b)), min(B(a), B(b)) };
    return true, BoundingBox(tl, br);
}

T         :: (using r: Rectangle) -> float { return y;         }
L         :: (using r: Rectangle) -> float { return x;         }
B         :: (using r: Rectangle) -> float { return y + h;     }
R         :: (using r: Rectangle) -> float { return x + w;     }
CX        :: (using r: Rectangle) -> float { return x + w / 2; }
CY        :: (using r: Rectangle) -> float { return y + h / 2; }

Center    :: (using r: Rectangle) -> Vector2 { return { CX(r), CY(r) }; }
TL        :: (using r: Rectangle) -> Vector2 { return { L (r), T (r) }; }
TC        :: (using r: Rectangle) -> Vector2 { return { CX(r), T (r) }; }
TR        :: (using r: Rectangle) -> Vector2 { return { R (r), T (r) }; }
BL        :: (using r: Rectangle) -> Vector2 { return { L (r), B (r) }; }
BC        :: (using r: Rectangle) -> Vector2 { return { CX(r), B (r) }; }
BR        :: (using r: Rectangle) -> Vector2 { return { R (r), B (r) }; }
CL        :: (using r: Rectangle) -> Vector2 { return { L (r), CY(r) }; }
CR        :: (using r: Rectangle) -> Vector2 { return { R (r), CY(r) }; }

SetT      :: (using r: *Rectangle, pos: float) { y = pos;         }
SetL      :: (using r: *Rectangle, pos: float) { x = pos;         }
SetB      :: (using r: *Rectangle, pos: float) { y = pos - h;     }
SetR      :: (using r: *Rectangle, pos: float) { x = pos - w;     }
SetCX     :: (using r: *Rectangle, pos: float) { x = pos - w / 2; }
SetCY     :: (using r: *Rectangle, pos: float) { y = pos - h / 2; }

SetCenter :: (using r: *Rectangle, pos: Vector2) { SetCX(r, pos.x); SetCY(r, pos.y); }
SetTL     :: (using r: *Rectangle, pos: Vector2) { SetL (r, pos.x); SetT (r, pos.y); }
SetTC     :: (using r: *Rectangle, pos: Vector2) { SetCX(r, pos.x); SetT (r, pos.y); }
SetTR     :: (using r: *Rectangle, pos: Vector2) { SetR (r, pos.x); SetT (r, pos.y); }
SetBL     :: (using r: *Rectangle, pos: Vector2) { SetL (r, pos.x); SetB (r, pos.y); }
SetBC     :: (using r: *Rectangle, pos: Vector2) { SetCX(r, pos.x); SetB (r, pos.y); }
SetBR     :: (using r: *Rectangle, pos: Vector2) { SetR (r, pos.x); SetB (r, pos.y); }
SetCL     :: (using r: *Rectangle, pos: Vector2) { SetL (r, pos.x); SetCY(r, pos.y); }
SetCR     :: (using r: *Rectangle, pos: Vector2) { SetR (r, pos.x); SetCY(r, pos.y); }

Size :: (using r: Rectangle) -> Vector2 {
    return { w, h };
}

HalfSize :: (using r: Rectangle) -> Vector2 {
    return Size(r) / 2;
}

Points :: (using r: Rectangle) -> [4] Vector2 {
    return .[ TL(r), TR(r), BR(r), BL(r) ];
}

Edges :: (using r: Rectangle) -> [4] Segment {
    return .[ { TL(r), TR(r) }, { TR(r), BR(r) }, { BR(r), BL(r) }, { BL(r), TL(r) } ];
}

Move :: (using r: *Rectangle, delta: Vector2) {
    x += delta.x;
    y += delta.y;
}

Resize :: (using r: *Rectangle, amount: Vector2) {
    r.* = MakeRectangleFromCenter(Center(r), Size(r) + amount);
}

Resize :: (using r: *Rectangle, amount: float) {
    r.* = MakeRectangleFromCenter(Center(r), Size(r) + { amount, amount });
}

CutL :: (using r: Rectangle, value: float) -> Rectangle, Rectangle {
    l := Rectangle.{ x      , y, value  , h };
    r := Rectangle.{ x+value, y, w-value, h };
    return l, r;
}

CutR :: (using r: Rectangle, value: float) -> Rectangle, Rectangle {
    r := Rectangle.{ x+w-value, y, value  , h };
    l := Rectangle.{ x        , y, w-value, h };
    return r, l;
}

CutT :: (using r: Rectangle, value: float) -> Rectangle, Rectangle {
    t := Rectangle.{ x, y      , w, value   };
    b := Rectangle.{ x, y+value, w, h-value };
    return t, b;
}

CutB :: (using r: Rectangle, value: float) -> Rectangle, Rectangle {
    b := Rectangle.{ x, y+h-value, w, value   };
    t := Rectangle.{ x, y        , w, h-value };
    return b, t;
}

CutLPercent :: (using r: Rectangle, percent: float) -> Rectangle, Rectangle {
    l, r := CutL(r, w * percent);
    return l, r;
}

CutRPercent :: (using r: Rectangle, percent: float) -> Rectangle, Rectangle {
    r, l := CutR(r, w * percent);
    return r, l;
}

CutTPercent :: (using r: Rectangle, percent: float) -> Rectangle, Rectangle {
    t, b := CutT(r, h * percent);
    return t, b;
}

CutBPercent :: (using r: Rectangle, percent: float) -> Rectangle, Rectangle {
    b, t := CutB(r, h * percent);
    return b, t;
}

Circle :: struct {
    x, y, r : float;
}

MakeCircle :: (position: Vector2, radius: float) -> Circle {
    return { position.x, position.y, radius };
}

Center :: (using c: Circle) -> Vector2 {
    return { x, y };
}

Move :: (using c: *Circle, delta: Vector2) {
    x += delta.x;
    y += delta.y;
}

Points :: (using circle: Circle, $nb_of_points: int) -> [nb_of_points] Vector2 {
    THETA_PER_POINT :: TAU / nb_of_points;
    points : [nb_of_points] Vector2;
    for * points  {
        c := cos(it_index * THETA_PER_POINT);
        s := sin(it_index * THETA_PER_POINT);
        it.* = Center(circle) + { c, s } * r;
    }
    return points;
}

BoundingCircle :: (a: Vector2, b: Vector2) -> Circle {
    center := (a + b) * 0.5;
    radius := distance(a, b) * 0.5;
    return MakeCircle(center, radius);
}

BoundingCircle :: (points: [] Vector2) -> Circle {
    box := BoundingBox(points);
    return BoundingCircle(box);
}

BoundingCircle :: (using s: Segment) -> Circle {
    return BoundingCircle(a, b);
}

BoundingCircle :: (using r: Rectangle) -> Circle {
    return BoundingCircle(TL(r), BR(r));
}

BoundingCircle :: (using p: Polygon) -> Circle {
    return BoundingCircle(points);
}

BoundingCircle :: (using e: Ellipse) -> Circle {
    return { x, y, max(w, h) };
}

BoundingCircle :: (using rs: Rounded_Segment) -> Circle {
    c := BoundingCircle(segment);
    return { c.x, c.y, c.r + r };
}

BoundingCircle :: (using rr: Rounded_Rectangle) -> Circle {
    c := BoundingCircle(rectangle);
    return { c.x, c.y, c.r + r };
}

BoundingCircle :: (using rp: Rounded_Polygon) -> Circle {
    c := BoundingCircle(polygon);
    return { c.x, c.y, c.r + r };
}

BoundingCircle :: (a: Circle, b: Circle) -> Circle {
    d := distance(Center(a), Center(b));
    if d + b.r <= a.r return a;
    if d + a.r <= b.r return b;
    radius := (d + a.r + b.r) * 0.5;
    theta  := (radius  - a.r) / d;
    center := Center(a) + theta * (Center(b) - Center(a));
    return MakeCircle(center, radius);
}

BoundingCircle :: (circles: [] Circle) -> Circle {
    result := circles[0];
    for circles result = BoundingCircle(result, it);
    return result;
}

Ellipse :: struct {
    x, y, w, h : float;
}

Center :: (using e: Ellipse) -> Vector2 {
    return { x, y };
}

Segment :: struct {
    a, b : Vector2;
}

MakeSegmentFromPolar :: (origin: Vector2, theta: float, length: float) -> Segment {
    return { origin, origin + VectorFromPolar(theta, length) };
}

MakeSegmentFromVector :: (origin: Vector2, vector: Vector2) -> Segment {
    return { origin, origin + vector };
}

MakeSegmentFromVector :: (vector: Vector2) -> Segment {
    origin := Vector2.{ 0, 0 };
    return { origin, origin + vector };
}

Center :: (using s: Segment) -> Vector2 {
    return (a + b) / 2;
}

Vector :: (using s: Segment) -> Vector2 {
    return b - a;
}

Direction :: (using s: Segment) -> Vector2 {
    return normalize(b - a);
}

Normal :: (using s: Segment) -> Vector2 {
    d := Direction(s);
    return { d.y, -d.x };
}

Angle :: (using s: Segment) -> float {
    return atan2(b.y - a.y, b.x - a.x);
}

Length :: (using s: Segment) -> float {
    return length(b - a);
}

LengthSquared :: (using s: Segment) -> float {
    return length_squared(b - a);
}

Points :: (using s: Segment) -> [2] Vector2 {
    return .[ a, b ];
}

Move :: (using s: *Segment, delta: Vector2) {
    s.* = { a + delta, b + delta };
}

SetA :: (using s: *Segment, p: Vector2) {
    s.* = MakeSegmentFromVector(p, Vector(s));
}

SetB :: (using s: *Segment, p: Vector2) {
    s.* = MakeSegmentFromVector(p, -Vector(s));
    swap(*a, *b);
}

DragA :: (using s: *Segment, p: Vector2) {
    s.* = MakeSegmentFromPolar(p, AngleBetween(p, b), Length(s));
}

DragB :: (using s: *Segment, p: Vector2) {
    s.* = MakeSegmentFromPolar(p, AngleBetween(p, a), Length(s));
    swap(*a, *b);
}

RotateAroundA :: (using s: *Segment, theta: float) {
    s.* = MakeSegmentFromPolar(s.a, AngleBetween(a, b) + theta, Length(s));
}

RotateAroundB :: (using s: *Segment, theta: float) {
    s.* = MakeSegmentFromPolar(s.b, AngleBetween(b, a) + theta, Length(s));
    swap(*a, *b);
}

Parallel :: (a: Segment, b: Segment) -> bool {
    return abs(Cross(Vector(a), Vector(b))) <= EPSILON;
}

Collinear :: (a: Segment, b: Segment) -> bool {
    return Collinear(a.a, a.b, b.a) && Collinear(a.a, a.b, b.b);
}

Polygon :: struct {
    points : [] Vector2;
}

for_expansion :: (using polygon: Polygon, body: Code, flags: For_Flags) #expand {
    REVERSE :: cast(bool) (flags & .REVERSE);
    POINTER :: cast(bool) (flags & .POINTER);

    for *=POINTER, <=REVERSE point, i : points {
        `it       := point;
        `it_index := i;

        #insert body;
    }
}

segments :: (using polygon: Polygon, body: Code, flags: For_Flags) #expand {
    REVERSE :: cast(bool) (flags & .REVERSE);

    for point, i : points {
        j := (i+1) % points.count;

        `it       := Segment.{ points[i], points[j] };
        `it_index := i;

        #insert body;
    }
}

MakePolygonFromPointCloud :: (points: [] Vector2) -> Polygon {
    hull : [..] Vector2;

    leftmost_idx := 0;
    for 1..points.count - 1 {
        if points[it].x < points[leftmost_idx].x {
            leftmost_idx = it;
        }
    }

    point_on_hull := points[leftmost_idx];
    endpoint : Vector2;

    while true {
        array_add(*hull, point_on_hull);
        endpoint = points[0];

        for 1..points.count - 1 {
            if (endpoint == point_on_hull) || Clockwise(point_on_hull, endpoint, points[it]) {
                endpoint = points[it];
            }
        }

        point_on_hull = endpoint;

        if endpoint == hull[0] break;
    }

    polygon: Polygon;
    polygon.points = hull;
    return polygon;
}

Center :: (using polygon: Polygon) -> Vector2 {
    center : Vector2;
    for points center += it;
    center /= cast(float) points.count;
    return center;
}

Centroid :: (using polygon: Polygon) -> Vector2 {
    area := 0.0;
    centroid : Vector2;
    for :segments polygon {
        cross := Cross(it.a, it.b);
        area += cross;
        centroid += cross * (it.a + it.b);
    }
    area *= 0.5;
    centroid /= 6.0 * area;
    return centroid;
}

TransformPolygon :: (using polygon: *Polygon, transform: $T/Transform_Type) {
    for * points TransformPoint(it, transform);
}

Rotate :: (using polygon: *Polygon, angle: float) {
    anchor := Center(polygon);
    t0 := TranslationMatrix(-anchor);
    r  := RotationMatrix(angle);
    t1 := TranslationMatrix(anchor);
    for * points TransformPoint(it, Matrix4.[ t0, r, t1 ]);
}

Move :: (using p: *Polygon, delta: Vector2) {
    for * points it.* += delta;
}

Clockwise :: (using polygon: Polygon) -> bool {
    for 0..points.count - 1 {
        i := points[it];
        j := points[(it+1) % points.count];
        k := points[(it+2) % points.count];
        if !Clockwise(i, j, k) return false;
    }
    return true;
}

CounterClockwise :: (using polygon: Polygon) -> bool {
    for 0..points.count - 1 {
        i := points[it];
        j := points[(it+1) % points.count];
        k := points[(it+2) % points.count];
        if !CounterClockwise(i, j, k) return false;
    }
    return true;
}

Convex :: (using polygon: Polygon) -> bool {
    return Clockwise(polygon) || CounterClockwise(polygon);
}

Rounded_Segment :: struct {
    using segment : Segment;
    r : float;
}

Rounded_Rectangle :: struct {
    using rectangle : Rectangle;
    r : float;
}

Rounded_Polygon :: struct {
    using polygon : Polygon;
    r : float;
}

ClosestPoint :: (a: Segment, b: Vector2) -> Vector2 {
    v0 := a.b - a.a;
    v1 := b - a.a;
    projection := dot(v1, v0) / length_squared(v0);
    Clamp(*projection, 0, 1);
    return a.a + v0 * projection;
}

ClosestPoint :: (a: Circle, b: Vector2) -> Vector2 {
    if Colliding(a, b) return b;
    return Center(a) + normalize(b - Center(a)) * a.r;
}

ClosestPoint :: (a: Rectangle, b: Vector2) -> Vector2 {
    x := clamp(b.x, L(a), R(a));
    y := clamp(b.y, T(a), B(a));
    return { x, y };
}

ClosestPoint :: (a: Polygon, b: Vector2) -> Vector2 {
    if Colliding(a, b) return b;
    return ClosestPointOnBorder(a, b);
}

ClosestPointOnBorder :: (a: Circle, b: Vector2) -> Vector2 {
    direction := b - Center(a);
    distance  := length(direction);
    if distance < EPSILON return Center(a) + { a.r, 0 };
    return Center(a) + (direction / distance) * a.r;
}

ClosestPointOnBorder :: (a: Rectangle, b: Vector2) -> Vector2 {
    return ClosestPointOnBorder(Polygon.{ Points(a) }, b);
}

ClosestPointOnBorder :: (a: Polygon, b: Vector2) -> Vector2 {
    closest_dist := FLOAT32_MAX;
    closest_point : Vector2;
    for :segments a {
        point := ClosestPoint(it, b);
        dist  := length_squared(point - b);
        if dist < closest_dist {
            closest_dist = dist;
            closest_point = point;
        }
    }
    return closest_point;
}

ClosestEdgeIndex :: (a: Rectangle, b: Vector2) -> int {
    return ClosestEdgeIndex(Polygon.{ Points(a) }, b);
}

ClosestEdgeIndex :: (a: Polygon, b: Vector2) -> int {
    closest_dist := FLOAT32_MAX;
    closest_edge_index: int;
    for :segments a {
        point := ClosestPoint(it, b);
        dist  := length_squared(point - b);
        if dist < closest_dist {
            closest_dist = dist;
            closest_edge_index = it_index;
        }
    }
    return closest_edge_index;
}

ClosestPoints :: (a: Segment, b: Segment) -> Vector2, Vector2 {
    va := Vector(a);
    vb := Vector(b);
    vt := a.a - b.a;

    g := dot(va, va);
    h := dot(vb, vb);
    i := dot(vb, vt);
    j := dot(va, vt);
    k := dot(va, vb);

    a_is_point := g <= EPSILON;
    b_is_point := h <= EPSILON;

    t, u : float;

    if a_is_point && b_is_point {
        t = 0.0;
        u = 0.0;
    } else if a_is_point {
        t = 0.0;
        u = clamp(i / h, 0.0, 1.0);
    } else if b_is_point {
        u = 0.0;
        t = clamp(-j / g, 0.0, 1.0);
    } else {
        denom := g * h - k * k;

        t = ifx denom != 0.0 then clamp((k * i - j * h) / denom, 0.0, 1.0) else 0.0;
        u = (k * t + i) / h;

        if u < 0.0 {
            t = clamp(-j / g, 0.0, 1.0);
            u = 0.0;
        } else if u > 1.0 {
            t = clamp((k - j) / g, 0.0, 1.0);
            u = 1.0;
        }
    }

    closest_a := a.a + va * t;
    closest_b := b.a + vb * u;

    return closest_a, closest_b;
}

Colliding :: (a: Vector2, b: Vector2) -> bool {
    return length(b - a) <= EPSILON;
}

Colliding :: (a: Vector2, b: Segment) -> bool #symmetric {
    if !Collinear(a, b.a, b.b) return false;
    v0 := b.b - b.a;
    v1 := a - b.a;
    d := dot(v1, v0);
    if d < 0 return false;
    return d <= length_squared(v0);
}

Colliding :: (a: Vector2, b: Circle) -> bool #symmetric {
    dx := a.x - b.x;
    dy := a.y - b.y;
    return (dx * dx) + (dy * dy) <= (b.r * b.r);
}

Colliding :: (a: Vector2, b: Rectangle) -> bool #symmetric {
    return !(R(b) < a.x || a.x < L(b) || B(b) < a.y || a.y < T(b));
}

Colliding :: (a: Vector2, b: Polygon) -> bool #symmetric {
    collision := false;
    for :segments b {
        crosses_y_bounds := (it.a.y > a.y) != (it.b.y > a.y);
        if crosses_y_bounds {
            intersect_x := a.x < (it.b.x - it.a.x) * (a.y - it.a.y) / (it.b.y - it.a.y) + it.a.x;
            if intersect_x collision = !collision;
        }
    }
    return collision;
}

Colliding :: (a: Vector2, b: Ellipse) -> bool #symmetric {
    dx := a.x - b.x;
    dy := a.y - b.y;
    return (dx * dx) / (b.w * b.w) + (dy * dy) / (b.h * b.h) <= 1.0;
}

Colliding :: (a: Vector2, b: Rounded_Segment) -> bool #symmetric {
    return distance(a, ClosestPoint(b.segment, a)) <= b.r;
}

Colliding :: (a: Vector2, b: Rounded_Rectangle) -> bool #symmetric {
    return distance(a, ClosestPoint(b.rectangle, a)) <= b.r;
}

Colliding :: (a: Vector2, b: Rounded_Polygon) -> bool #symmetric {
    return distance(a, ClosestPoint(b.polygon, a)) <= b.r;
}

Colliding :: (a: Segment, b: Segment) -> bool {
    if Length(a) < EPSILON || Length(b) < EPSILON return false;
    if Collinear(a, b) return Colliding(a, b.a) || Colliding(a, b.b) || Colliding(b, a.a) || Colliding(b, a.b);
    x := Cross(b.a - a.a, b.b - b.a) / Cross(a.b - a.a, b.b - b.a);
    y := Cross(b.a - a.a, a.b - a.a) / Cross(a.b - a.a, b.b - b.a);
    return !(x < 0 || x > 1 || y < 0 || y > 1);
}

Colliding :: (a: Segment, b: Circle) -> bool #symmetric {
    closest := ClosestPoint(a, Center(b));
    return length_squared(closest - Center(b)) <= (b.r * b.r);
}

Colliding :: (a: Segment, b: Rectangle) -> bool #symmetric {
    if Colliding(a.a, b) || Colliding(a.b, b) return true;
    for Edges(b) if Colliding(a, it) return true;
    return false;
}

Colliding :: (a: Segment, b: Polygon) -> bool #symmetric {
    if Colliding(a.a, b) || Colliding(a.b, b) return true;
    for :segments b if Colliding(a, it) return true;
    return false;
}

Colliding :: (a: Rectangle, b: Rectangle) -> bool {
    return !(R(a) < L(b) || R(b) < L(a) || B(a) < T(b) || B(b) < T(a));
}

Colliding :: (a: Circle, b: Circle) -> bool {
    return length_squared(Center(b) - Center(a)) <= (a.r+b.r) * (a.r+b.r);
}

Colliding :: (a: Circle, b: Rectangle) -> bool #symmetric {
    closest := ClosestPoint(b, Center(a));
    return Colliding(a, closest);
}

Colliding :: (a: Circle, b: Polygon) -> bool #symmetric  {
    if Colliding(Center(a), b) return true;
    closest := ClosestPoint(b, Center(a));
    return length_squared(closest - Center(a)) <= (a.r * a.r);
}

Colliding :: (a: Rectangle, b: Polygon) -> bool #symmetric {
    return Colliding(Polygon.{ Points(a) }, b);
}

Colliding :: (a: Polygon, b: Polygon) -> bool {
    ProjectionRange :: (polygon: Polygon, axis: Vector2) -> float, float {
        min := +FLOAT32_MAX;
        max := -FLOAT32_MAX;
        for polygon {
            d := dot(it, axis);
            min = Min(min, d);
            max = Max(max, d);
        }
        return min, max;
    }

    for :segments a {
        n := Normal(it);
        min_a, max_a := ProjectionRange(a, n);
        min_b, max_b := ProjectionRange(b, n);
        if max_a < min_b || max_b < min_a return false;
    }

    for :segments b {
        n := Normal(it);
        min_a, max_a := ProjectionRange(a, n);
        min_b, max_b := ProjectionRange(b, n);
        if max_a < min_b || max_b < min_a return false;
    }

    return true;
}

Contains :: (a: Circle, b: Vector2) -> bool {
    return Colliding(a, b);
}

Contains :: (a: Circle, b: [] Vector2) -> bool {
    for b if !Colliding(a, it) return false;
    return true;
}

Contains :: (a: Circle, b: Segment) -> bool {
    return Contains(a, Points(b));
}

Contains :: (a: Circle, b: Circle) -> bool {
    return length_squared(Center(a) - Center(b)) <= (a.r - b.r) * (a.r - b.r);
}

Contains :: (a: Circle, b: Rectangle) -> bool {
    return Contains(a, Points(b));
}

Contains :: (a: Circle, b: Polygon) -> bool {
    return Contains(a, b.points);
}

Contains :: (a: Rectangle, b: Vector2) -> bool {
    return Colliding(a, b);
}

Contains :: (a: Rectangle, b: [] Vector2) -> bool {
    for b if !Colliding(a, it) return false;
    return true;
}

Contains :: (a: Rectangle, b: Segment) -> bool {
    return Contains(a, Points(b));
}

Contains :: (a: Rectangle, b: Circle) -> bool {
    return Contains(a, BoundingBox(b));
}

Contains :: (a: Rectangle, b: Rectangle) -> bool {
    return Contains(a, Vector2.[ TL(b), BR(b) ]);
}

Contains :: (a: Rectangle, b: Polygon) -> bool {
    return Contains(a, b.points);
}

Contains :: (a: Polygon, b: Vector2) -> bool {
    return Colliding(a, b);
}

Contains :: (a: Polygon, b: [] Vector2) -> bool {
    for b if !Colliding(a, it) return false;
    return true;
}

Contains :: (a: Polygon, b: Segment) -> bool {
    return Contains(a, Points(b));
}

Contains :: (a: Polygon, b: Circle) -> bool {
    if !Contains(a, Center(b)) return false;
    closest := ClosestPointOnBorder(a, Center(b));
    return distance(closest, Center(b)) >= b.r;
}

Contains :: (a: Polygon, b: Rectangle) -> bool {
    return Contains(a, Points(b));
}

Contains :: (a: Polygon, b: Polygon) -> bool {
    return Contains(a, b.points);
}

Cube :: struct {
    position, size : Vector3;
}

MakeCubeFromCenter :: (center: Vector3, size: Vector3) -> Cube {
    min := center - size/2;
    max := center + size/2;
    return BoundingCube(min, max);
}

MakeCubeFromCenter :: (center: Vector3, size: float) -> Cube {
    return MakeCubeFromCenter(center, { size, size, size });
}

MinkowskiDif :: (a: Cube, b: Cube) -> Cube {
    return { Min(a) - Max(b), a.size + b.size };
}

BoundingCube :: (a: Vector3, b: Vector3) -> Cube {
    x := min(a.x, b.x);
    y := min(a.y, b.y);
    z := min(a.z, b.z);
    w := max(a.x, b.x) - x;
    h := max(a.y, b.y) - y;
    d := max(a.z, b.z) - z;
    return { { x, y, z }, { w, h, d } };
}

BoundingCube :: (points: [] Vector3) -> Cube {
    x0, y0, z0 := +FLOAT32_MAX;
    x1, y1, z1 := -FLOAT32_MAX;
    for points {
        x0 = min(x0, it.x);
        y0 = min(y0, it.y);
        z0 = min(z0, it.z);
        x1 = max(x1, it.x);
        y1 = max(y1, it.y);
        z1 = max(z1, it.z);
    }
    return BoundingCube({ x0, y0, z0 }, { x1, y1, z1 });
}

BoundingCube :: (a: Cube, b: Vector3) -> Cube #symmetric {
    return BoundingCube(Vector3.[ Min(a), Max(a), b ]);
}

BoundingCube :: (a: Cube, b: Cube) -> Cube {
    return BoundingCube(min(Min(a), Min(b)), max(Max(a), Max(b)));
}

BoundingCube :: (cubes : [] Cube) -> Cube {
    result := cubes[0];
    for cubes result = BoundingCube(result, it);
    return result;
}

Center :: (using cube: Cube) -> Vector3 {
    return position + size / 2;
}

Min :: (using cube: Cube) -> Vector3 {
    return position;
}

Max :: (using cube: Cube) -> Vector3 {
    return position + size;
}

Move :: (using cube: *Cube, delta: Vector3) {
    position += delta;
}

Colliding :: (a: Cube, b: Cube) -> bool {
    a_min, a_max := Min(a), Max(a);
    b_min, b_max := Min(b), Max(b);
    if a_max.x < b_min.x || b_max.x < a_min.x return false;
    if a_max.y < b_min.y || b_max.y < a_min.y return false;
    if a_max.z < b_min.z || b_max.z < a_min.z return false;
    return true;
}

Colliding :: (a: Cube, b: Vector3) -> bool #symmetric {
    a_min, a_max := Min(a), Max(a);
    if a_max.x < b.x || a_min.x > b.x return false;
    if a_max.y < b.y || a_min.y > b.y return false;
    if a_max.z < b.z || a_min.z > b.z return false;
    return true;
}

Transform :: struct {
    translation : Vector2;
    rotation    : float;
    scaling     : Vector2 = { 1, 1 };
}

Transform_Type :: Type.[ Transform, Matrix4 ];
Scaling_Type   :: Type.[ float, Vector2 ];

ToTransform :: (using matrix: Matrix4) -> Transform {
    using transform : Transform;
    translation = { floats[3], floats[7] };
    rotation    = atan2(floats[4], floats[0]);
    scaling     = { length({ floats[0], floats[4] }), length({ floats[1], floats[5] }) };
    return transform;
}

ToMatrix :: (using transform: Transform) -> Matrix4 {
    S := ScalingMatrix(scaling);
    R := RotationMatrix(rotation);
    T := TranslationMatrix(translation);
    return T * R * S;
}

TranslationMatrix :: (using translation: Vector2) -> Matrix4 {
    using matrix := Matrix4_Identity;
    floats[3] = x;
    floats[7] = y;
    return matrix;
}

RotationMatrix :: (rotation: float) -> Matrix4 {
    c, s := cos(rotation), sin(rotation);
    using matrix := Matrix4_Identity;
    floats[0] =  c;
    floats[4] =  s;
    floats[1] = -s;
    floats[5] =  c;
    return matrix;
}

ScalingMatrix :: (scaling: $T/Scaling_Type) -> Matrix4 {
    using matrix := Matrix4_Identity;
    floats[0] = #ifx T == Vector2 then scaling.x else scaling;
    floats[5] = #ifx T == Vector2 then scaling.y else scaling;
    return matrix;
}

TransformPoint :: (point: Vector2, matrix: Matrix4) -> Vector2 {
    return (matrix * { point.x, point.y, 0.0, 1.0 }).xy;
}

TransformPoint :: (point: Vector2, transform: Transform) -> Vector2 {
    return TransformPoint(point, ToMatrix(transform));
}

TransformPoint :: (point: Vector2, transforms: [] $T/Transform_Type) -> Vector2 {
    result := point;
    for transforms result = TransformPoint(result, it);
    return result;
}

TransformPoint :: (point: *Vector2, matrix: Matrix4) {
    point.* = (matrix * { point.x, point.y, 0.0, 1.0 }).xy;
}

TransformPoint :: (point: *Vector2, transform: Transform) {
    point.* = TransformPoint(point.*, ToMatrix(transform));
}

TransformPoint :: (point: *Vector2, transforms: [] $T/Transform_Type) {
    point.* = TransformPoint(point.*, transforms);
}

InverseTransformPoint :: (point: Vector2, matrix: Matrix4) -> Vector2 {
    ok, i := inverse(matrix);
    assert(ok);
    return TransformPoint(point, i);
}

InverseTransformPoint :: (point: Vector2, transform: Transform) -> Vector2 {
    return InverseTransformPoint(point, ToMatrix(transform));
}

InverseTransformPoint :: (point: Vector2, transforms: [] $T/Transform_Type) -> Vector2 {
    result := point;
    for < transforms result = InverseTransformPoint(result, it);
    return result;
}

InverseTransformPoint :: (point: *Vector2, matrix: Matrix4) {
    point.* = InverseTransformPoint(point.*, matrix);
}

InverseTransformPoint :: (point: *Vector2, transform: Transform) {
    point.* = InverseTransformPoint(point.*, ToMatrix(transform));
}

InverseTransformPoint :: (point: *Vector2, transforms: [] $T/Transform_Type) {
    point.* = InverseTransformPoint(point.*, transforms);
}

Camera :: struct {
    using transform : Transform;
    focus : Vector2;
}

TransformPoint :: (point: Vector2, using camera: Camera) -> Vector2 {
    a := TranslationMatrix(-translation);
    b := RotationMatrix(rotation);
    c := ScalingMatrix(scaling);
    d := TranslationMatrix(focus);
    return TransformPoint(point, Matrix4.[ a, b, c, d ]);
}

InverseTransformPoint :: (point: Vector2, using camera: Camera) -> Vector2 {
    a := TranslationMatrix(-translation);
    b := RotationMatrix(rotation);
    c := ScalingMatrix(scaling);
    d := TranslationMatrix(focus);
    return InverseTransformPoint(point, Matrix4.[ a, b, c, d ]);
}

Move :: (using camera: *Camera, delta: Vector2) {
    translation += rotate(delta, -rotation) / scaling;
}

SetFocus :: (using camera: *Camera, position: Vector2) {
    delta := position - focus;
    focus += delta;
    Move(camera, delta);
}

Vector2Int :: struct {
    x, y: int;
}

ToVector :: (using v : Vector2Int) -> Vector2 {
    return { xx x, xx y };
}

ToVectorInt :: (using v : Vector2) -> Vector2Int {
    return { xx x, xx y };
}

operator + :: (a: Vector2Int, b: Vector2Int) -> Vector2Int {
    return { a.x+b.x, a.y+b.y };
}

operator - :: (a: Vector2Int, b: Vector2Int) -> Vector2Int {
    return { a.x-b.x, a.y-b.y };
}

operator - :: (a: Vector2Int) -> Vector2Int {
    return { -a.x, -a.y };
}

operator * :: (a: Vector2Int, b: Vector2Int) -> Vector2Int {
    return { a.x*b.x, a.y*b.y };
}

operator * :: (a: Vector2Int, k: int) -> Vector2Int #symmetric {
    return { a.x*k, a.y*k };
}

operator * :: (a: Vector2Int, k: float) -> Vector2Int #symmetric {
    return ToVectorInt({ a.x*k, a.y*k });
}

operator / :: (a: Vector2Int, b: Vector2Int) -> Vector2Int {
    return { a.x/b.x, a.y/b.y };
}

operator / :: (a: Vector2Int, k: int) -> Vector2Int {
    denom := 1 / k;
    return { a.x*denom, a.y*denom };
}

operator / :: (k: int, a: Vector2Int) -> Vector2Int {
    return { k/a.x, k/a.y };
}

operator == :: (a: Vector2Int, b: Vector2Int) -> bool {
    return a.x == b.x && a.y == b.y;
}

Vector3Int :: struct {
    x, y, z: int;
}

ToVector :: (using v : Vector3Int) -> Vector3 {
    return { xx x, xx y, xx z };
}

ToVectorInt :: (using v : Vector3) -> Vector3Int {
    return { xx x, xx y, xx z };
}

operator + :: (a: Vector3Int, b: Vector3Int) -> Vector3Int {
    return { a.x+b.x, a.y+b.y, a.z+b.z };
}

operator - :: (a: Vector3Int, b: Vector3Int) -> Vector3Int {
    return { a.x-b.x, a.y-b.y, a.z-b.z };
}

operator - :: (a: Vector3Int) -> Vector3Int {
    return { -a.x, -a.y, -a.z };
}

operator * :: (a: Vector3Int, b: Vector3Int) -> Vector3Int {
    return { a.x*b.x, a.y*b.y, a.z*b.z };
}

operator * :: (a: Vector3Int, k: int) -> Vector3Int #symmetric {
    return { a.x*k, a.y*k, a.z*k };
}

operator * :: (a: Vector3Int, k: float) -> Vector3Int #symmetric {
    return ToVectorInt({ a.x*k, a.y*k, a.z*k });
}

operator / :: (a: Vector3Int, b: Vector3Int) -> Vector3Int {
    return { a.x/b.x, a.y/b.y, a.z/b.z };
}

operator / :: (a: Vector3Int, k: int) -> Vector3Int {
    denom := 1 / k;
    return { a.x*denom, a.y*denom, a.z*denom };
}

operator / :: (k: int, a: Vector3Int) -> Vector3Int {
    return { k/a.x, k/a.y, k/a.z };
}

operator == :: (a: Vector3Int, b: Vector3Int) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

HexToRGB :: (hex: int) -> Vector3Int {
    r := (hex >> 16) & 0xFF;
    g := (hex >> 08) & 0xFF;
    b := (hex >> 00) & 0xFF;
    return { r, g, b };
}

Vector4Int :: struct {
    x, y, z, w : int;
}

ToVector :: (using v : Vector4Int) -> Vector4 {
    return { xx x, xx y, xx z, xx w };
}

ToVectorInt :: (using v : Vector4) -> Vector4Int {
    return { xx x, xx y, xx z, xx w };
}

operator + :: (a: Vector4Int, b: Vector4Int) -> Vector4Int {
    return { a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w };
}

operator - :: (a: Vector4Int, b: Vector4Int) -> Vector4Int {
    return { a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w };
}

operator - :: (a: Vector4Int) -> Vector4Int {
    return { -a.x, -a.y, -a.z, -a.w };
}

operator * :: (a: Vector4Int, b: Vector4Int) -> Vector4Int {
    return { a.x*b.x, a.y*b.y, a.z*b.z, a.w*b.w };
}

operator * :: (a: Vector4Int, k: int) -> Vector4Int #symmetric {
    return { a.x*k, a.y*k, a.z*k, a.w*k };
}

operator * :: (a: Vector4Int, k: float) -> Vector4Int #symmetric {
    return ToVectorInt({ a.x*k, a.y*k, a.z*k, a.w*k });
}

operator / :: (a: Vector4Int, b: Vector4Int) -> Vector4Int {
    return { a.x/b.x, a.y/b.y, a.z/b.z, a.w/b.w };
}

operator / :: (a: Vector4Int, k: int) -> Vector4Int {
    denom := 1 / k;
    return { a.x*denom, a.y*denom, a.z*denom, a.w*denom };
}

operator / :: (k: int, a: Vector4Int) -> Vector4Int {
    return { k/a.x, k/a.y, k/a.z, k/a.w };
}

operator == :: (a: Vector4Int, b: Vector4Int) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}

HexToRGBA :: (hex: int) -> Vector4Int {
    r := (hex >> 24) & 0xFF;
    g := (hex >> 16) & 0xFF;
    b := (hex >> 08) & 0xFF;
    a := (hex >> 00) & 0xFF;
    return { r, g, b, a };
}

Static_Array :: struct(capacity: int, type: Type) {
    count : int;
    data  : [capacity] type;
}

operator *[] :: (array: *Static_Array, index: int) -> *array.type {
    assert(index >= 0);
    assert(index < array.count);
    return *array.data[index];
}

for_expansion :: (array: *$T/Static_Array, body: Code, flags: For_Flags) #expand {
    REVERSE :: cast(bool) (flags & .REVERSE);
    POINTER :: cast(bool) (flags & .POINTER);

    for <=REVERSE i : 0..array.count - 1 {
        `it       := #ifx POINTER then *array.data[i] else array.data[i];
        `it_index := i;

        #insert (remove={ unordered_remove_by_index(array, i); }) body;
    }
}

array_add :: (array: *Static_Array, item: array.type) {
    array.data[array.count] = item;
    array.count += 1;
}

array_add :: (array: *Static_Array, to_append: ..array.type) {
    for to_append array_add(array, it);
}

array_add_if_unique :: (array: *Static_Array, item: array.type) -> bool, int {
    found, index := array_find(array, item);
    if found return false, index;

    array_add(array, item);
    return true, array.count - 1;
}

array_insert_at :: (array: *Static_Array, item: array.type, index: int) {
    assert(index >= 0);
    assert(index <= array.count);
    array.data[index] = item;
}

unordered_remove_by_value :: (array: *Static_Array, item: array.type, $stop_after_first := false) -> int {
    removed := 0;
    for array.*  if it == item {
        removed += 1;
        remove it;

        #if stop_after_first break;
    }

    return removed;
}

unordered_remove_by_index :: (array: *Static_Array, index: int) {
    assert(index >= 0);
    assert(index < array.count);

    last_index := array.count - 1;
    if index != last_index  array.data[index] = array.data[last_index];

    array.count -= 1;
}

ordered_remove_by_value :: (array: *Static_Array, item: array.type) -> bool {
    found, index := array_find(array, item);
    if found ordered_remove_by_index(array, index);
    return found;
}

ordered_remove_by_index :: (array: *Static_Array, index: int) {
    assert(index >= 0);
    assert(index < array.count);

    for i : index..array.count-2
        array.data[i] = array.data[i+1];

    array.count -= 1;
}

array_find :: (array: *Static_Array, item: array.type) -> bool, int {
    for array if it == item return true, it_index;
    return false, -1;  // Not found.
}

pop :: (array: *Static_Array, item: array.type) {
    array.count -= 1;
}

peek :: inline (array: *Static_Array) -> array.type {
    return array.data[array.count-1];
}

peek_pointer :: inline (array: *Static_Array) -> *array.type {
    return *array.data[array.count-1];
}

array_reset :: (array: *Static_Array) {
    array.count = 0;
}

Grid :: struct(cols: int, rows: int, type: Type) {
    cells : [cols][rows] type;
}

for_expansion :: (using grid: *Grid, body: Code, flags: For_Flags) #expand {
    REVERSE :: cast(bool) (flags & .REVERSE);
    POINTER :: cast(bool) (flags & .POINTER);

    for <=REVERSE, col : 0..grid.cols - 1 {
        for <=REVERSE, row : 0..grid.rows - 1 {
            `col_index := col;
            `row_index := row;

            `it_index := IndexFromCoords(grid, col, row);

            #if POINTER {
                `it := *grid.cells[col_index][row_index];
            } else {
                `it := grid.cells[col_index][row_index];
            }

            #insert (remove=#assert(false), break=break col, continue=continue row) body;
        }
    }
}

operator *[] :: (grid: *Grid, index: int) -> *[grid.rows] grid.type {
    return *grid.cells[index];
}

IndexFromCoords :: (using grid: Grid, col: int, row: int) -> bool, int {
    return Contains(grid, col, row), col * rows + row;
}

CoordsFromIndex :: (using grid: Grid, index: int) -> bool, int, int {
    return Contains(grid, index), index / rows, index % rows;
}

Contains :: (using grid: Grid, col: int, row: int) -> bool {
    return !(row < 0 || row >= rows || col < 0 || col >= cols);
}

Contains :: (using grid: Grid, index: int) -> bool {
    return !(index < 0 || index >= cols * rows);
}

At :: (using grid: *Grid, col: int, row: int) -> *grid.type {
    if !Contains(grid, col, row) return null;
    return *grid.*[col][row];
}

At :: (using grid: *Grid, index: int) -> *grid.type {
    ok, col, row := CoordsFromIndex(index);
    if !ok return null;
    return *grid.*[col][row];
}

AtCol :: (using grid: *Grid, col: int) -> [grid.rows] *grid.type {
    result : [grid.rows] *grid.type;
    for 0..grid.rows - 1 result[it] = At(grid, it, col);
    return result;
}

AtRow :: (using grid: *Grid, row: int) -> [grid.cols] *grid.type {
    result : [grid.cols] *grid.type;
    for 0..grid.cols - 1 result[it] = At(grid, col, row);
    return result;
}

Spring :: struct(type: Type) {
	value    : type;
    target   : type;
    halflife : float;
    hertz    : float;
	velocity : type;
}

Init :: (spring: *Spring, value: spring.type, halflife := 0.1, hertz := 4.0) {
	spring.value    = value;
    spring.target   = value;
    spring.halflife = halflife;
    spring.hertz    = hertz;
}

Update :: (using spring: *Spring, dt: float) {
    frequency := hertz * TAU;
	damping   := -log(0.5) / (frequency * halflife);

    restoration_force := (target - value) * frequency * frequency;
    damping_force     := -2.0 * damping * frequency * velocity;

    forces := (damping_force + restoration_force);

    velocity += forces   * dt;
    value    += velocity * dt;
}

Lerp :: (pointer: *$T, start: T, end: T, percent: float) {
    pointer.* = start + (end - start) * percent;
}

Lerp :: (pointer: *$T, end: T, percent: float) {
    pointer.* += (end - pointer.*) * percent;
}

Out :: (fn: (float) -> float, x: float) -> float {
    return 1 - fn(1 - x);
}

InOut :: (fn: (float) -> float, x: float) -> float {
    return (ifx x < .5 then fn(x*2) else 1 + Out(fn, x*2 - 1)) / 2;
}

Yoyo :: (fn: (float) -> float, x: float) -> float {
    return (ifx x < .5 then fn(x*2) else 1 - fn(x*2 - 1));
}

InQuad     :: (x: float) -> float { return x*x;                    }
InCubic    :: (x: float) -> float { return x*x*x;                  }
InQuart    :: (x: float) -> float { return x*x*x*x;                }
InQuint    :: (x: float) -> float { return x*x*x*x*x;              }
InSine     :: (x: float) -> float { return 1 - sin((1-x)*HALF_PI); }
InCirc     :: (x: float) -> float { return 1 - sqrt(1-x*x);        }
InExpo     :: (x: float) -> float { return pow(2, (x-1)*10);       }

OutQuad    :: #bake_arguments Out(fn = InQuad);
OutCubic   :: #bake_arguments Out(fn = InCubic);
OutQuart   :: #bake_arguments Out(fn = InQuart);
OutQuint   :: #bake_arguments Out(fn = InQuint);
OutSine    :: #bake_arguments Out(fn = InSine);
OutCirc    :: #bake_arguments Out(fn = InCirc);
OutExpo    :: #bake_arguments Out(fn = InExpo);

InOutQuad  :: #bake_arguments InOut(fn = InQuad);
InOutCubic :: #bake_arguments InOut(fn = InCubic);
InOutQuart :: #bake_arguments InOut(fn = InQuart);
InOutQuint :: #bake_arguments InOut(fn = InQuint);
InOutSine  :: #bake_arguments InOut(fn = InSine);
InOutCirc  :: #bake_arguments InOut(fn = InCirc);
InOutExpo  :: #bake_arguments InOut(fn = InExpo);

CounterClockwise :: (a: Vector2, b: Vector2, c: Vector2) -> bool {
    return Cross(b - a, c - b) < EPSILON;
}

Clockwise :: (a: Vector2, b: Vector2, c: Vector2) -> bool {
    return Cross(b - a, c - b) > EPSILON;
}

Collinear :: (a: Vector2, b: Vector2, c: Vector2) -> bool {
    return abs(Cross(b - a, c - a)) <= EPSILON;
}

Cross :: (a: Vector2, b: Vector2) -> float {
    return a.x * b.y - a.y * b.x;
}

AngleBetween :: (a: Vector2, b: Vector2) -> float {
    return atan2(b.y - a.y, b.x - a.x);
}

VectorFromPolar :: (theta: float, length: float) -> Vector2 {
    return { cos(theta) , sin(theta) } * length;
}

Sign :: (x: float) -> float {
    if x > 0.0 return +1.0;
    if x < 0.0 return -1.0;
    return 0.0;
}

Closest :: (x: float, a: float, b: float) -> float {
    return ifx abs(a - x) < abs(b - x) then a else b;
}

ChangeRandomSeed :: () {
    random_seed(cast(S128) current_time_consensus());
}

RandomFloat :: () -> float {
    return random_get_zero_to_one();
}

RandomFloat :: (min: float, max: float) -> float {
    return random_get_within_range(min, max);
}

RandomFloat :: (max: float) -> float {
    return random_get_within_range(0.0, max);
}

RandomInt :: () -> int {
    return xx random_get_within_range(xx S64_MIN, xx S64_MAX);
}

RandomInt :: (min: int, max: int) -> int {
    return xx random_get_within_range(xx min, max + .999);
}

RandomInt :: (max: int) -> int {
    return xx random_get_within_range(0.0, max + .999);
}

RandomItem :: (array: [] $T) -> T {
    index := RandomInt(array.count - 1);
    return array[index];
}

RandomItemPointer :: (array: [] $T) -> *T {
    index := RandomInt(array.count - 1);
    return *array[index];
}

RandomEnumValue :: ($T: Type) -> T {
    values := enum_values_as_enum(T);
    return RandomItem(values);
}

RandomBool :: () -> bool {
    return RandomFloat() > 0.5;
}

RandomPoint :: (s: Segment) -> Vector2 {
    return s.a + VectorFromPolar(Angle(s), RandomFloat(Length(s)));
}

RandomPoint :: (c: Circle) -> Vector2 {
    return Center(c) + VectorFromPolar(RandomFloat(TAU), RandomFloat(c.r));
}

RandomPoint :: (r: Rectangle) -> Vector2 {
    return { RandomFloat(L(r), R(r)), RandomFloat(T(r), B(r)) };
}

#scope_file

EPSILON :: 0.00001;
HALF_PI :: PI / 2;

#import "Basic";
#import "Math";
#import "Random";