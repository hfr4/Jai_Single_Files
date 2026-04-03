main :: () {
    the_window = Window.create_window(1400, 900, ApplicationTitle);
    Simp.set_render_target(the_window);

    application_render_target := Simp.texture_create_render_target(ApplicationWidth, ApplicationHeight, .RGBA8);

    Sound_Player.sound_player_init({});
    defer Sound_Player.sound_player_shutdown();

    ApplicationInit();
    ApplicationReset();

    last_time, last_update : float64;

    while !ShouldQuit() {
        dt := seconds_since_init() - last_time;
        last_time, last_update += dt;

        Input.update_window_events();
        for Input.get_window_resizes() Simp.update_window(the_window);

        ApplicationEvents();

        seconds_per_frame :: 1.0 / 60;
        while last_update >= seconds_per_frame {
            ApplicationUpdate(seconds_per_frame);
            last_update -= seconds_per_frame;
        }

        Sound_Player.update();

        Simp.set_render_target(*application_render_target, .LEFT_HANDED);
        Simp.clear_render_target(0, 0, 0, 1);
        ApplicationRender();

        Simp.set_render_target(the_window, .LEFT_HANDED);
        Simp.clear_render_target(0, 0, 0, 1);
        DrawTexture(application_render_target, ApplicationRectangleOnWindow());

        Simp.swap_buffers(the_window);

        reset_temporary_storage();
        sleep_milliseconds(10);
    }
}

ShouldQuit :: () -> bool {
    for Input.events_this_frame if it.type == .QUIT return true;
    return false;
}

Quit :: () {
    array_add(*Input.events_this_frame, { type = .QUIT });
}

Reset :: () {
    ApplicationReset();
}

Pressed :: (key: $T/.[ Input.Key_Code, u8 ]) -> bool {
    return xx Input.input_button_states[key] & .START;
}

Released :: (key: $T/.[ Input.Key_Code, u8 ]) -> bool {
    return xx Input.input_button_states[key] & .END;
}

Down :: (key: $T/.[ Input.Key_Code, u8 ]) -> bool {
    return xx Input.input_button_states[key] & .DOWN;
}

WindowRectangle :: () -> Rectangle {
    x, y, w, h := Window.get_dimensions(the_window, false);
    return { 0, 0, xx w, xx h };
}

ApplicationRectangle :: () -> Rectangle {
    return { 0, 0, ApplicationWidth, ApplicationHeight };
}

WindowCenter :: () -> Vector2 {
    return Center(WindowRectangle());
}

ApplicationCenter :: () -> Vector2 {
    return Center(ApplicationRectangle());
}

AspectRatio :: () -> float {
    ratio := Size(WindowRectangle()) / Size(ApplicationRectangle());
	return min(ratio.x, ratio.y);
}

WindowToApplication :: (position: Vector2) -> Vector2 {
    t := TranslationMatrix(-Center(WindowRectangle()) + HalfSize(ApplicationRectangle()) * AspectRatio());
    s := ScalingMatrix(1 / AspectRatio());
    return TransformPoint(position, s * t);
}

ApplicationToWindow :: (position: Vector2) -> Vector2 {
    t := TranslationMatrix(Center(WindowRectangle()) - HalfSize(ApplicationRectangle()) * AspectRatio());
    s := ScalingMatrix(AspectRatio());
    return TransformPoint(position, t * s);
}

ApplicationRectangleOnWindow :: () -> Rectangle {
    r := ApplicationRectangle();
    return BoundingBox(ApplicationToWindow(TL(r)), ApplicationToWindow(BR(r)));
}

MousePositionOnWindow :: () -> Vector2 {
	x, y := Window.get_mouse_pointer_position(the_window, false);
	return { xx x, xx y };
}

MousePositionOnApplication :: () -> Vector2 {
	return WindowToApplication(MousePositionOnWindow());
}

MousePositionOnCamera :: (camera: Camera) -> Vector2 {
    return InverseTransformPoint(MousePositionOnApplication(), camera);
}

CameraQuadOnApplication :: (camera: Camera) -> [4] Vector2 {
    rect := ApplicationRectangle();
    tl := InverseTransformPoint(TL(rect), camera);
    tr := InverseTransformPoint(TR(rect), camera);
    br := InverseTransformPoint(BR(rect), camera);
    bl := InverseTransformPoint(BL(rect), camera);
    return .[ tl, tr, br, bl ];
}

MouseDeltaOnWindow :: () -> Vector2 {
	return { xx Input.mouse_delta_x, xx Input.mouse_delta_y };
}

MouseDeltaOnApplication :: () -> Vector2 {
    s := ScalingMatrix(1 / AspectRatio());
	return TransformPoint(MouseDeltaOnWindow(), s);
}

LoadSound :: (path: string) -> Sound {
    sound : Sound;
    if      file_exists(path)                 sound = Sound_Player.load_audio_file(path);
    else if file_exists(tprint("../%", path)) sound = Sound_Player.load_audio_file(tprint("../%", path));
    assert(sound.loaded);
    return sound;
}

PlaySound :: (sound: *Sound) -> *Stream {
    stream := Sound_Player.make_stream(sound, .GENERAL_SFX);
    Sound_Player.start_playing(stream);
    return stream;
}

PlayMusic :: (music: *Sound) -> *Stream {
	stream := Sound_Player.make_stream(music, .MUSIC);
	Sound_Player.set_repeating(stream, true);
	Sound_Player.start_playing(stream);
    return stream;
}

StopAllSounds :: () {
    Sound_Player.stop_all_sounds_abruptly(0);
}

#load "Draw.jai";
#load "Utilities.jai";

the_window : Window.Window_Type;

Sound   :: Sound_Player.Sound_Data;
Stream  :: Sound_Player.Sound_Stream;
Texture :: Simp.Texture;
Bitmap  :: Simp.Bitmap;
Font    :: Simp.Dynamic_Font;

GL           :: #import "GL";
Simp         :: #import "Simp";
Input        :: #import "Input";
Window       :: #import "Window_Creation";
Sound_Player :: #import "Sound_Player";

#import "Basic";
#import "Math";
#import "Sort";
#import "File";
#import "File_Utilities";
