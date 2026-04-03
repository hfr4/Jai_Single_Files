#run build();

build :: () {
    set_build_options_dc({ do_output = false });

    files := choose_which_file_to_build();

    delete_directory(BUILD_FOLDER);
    make_directory_if_it_does_not_exist(BUILD_FOLDER);

    for files build_one(it, run_after_build = (files.count == 1));
}

choose_which_file_to_build :: () -> [..] string {
    using options := get_build_options();
    assert(compile_time_command_line.count == 1, "You can either pass a specific file name 'jai first.jai - the_file' or 'jai first.jai - all' to build all the files at once.");

    all_files := file_list(SOURCE_FOLDER);
    files_to_build : [..] string;

    if array_find(compile_time_command_line, "all") {
        array_add(*files_to_build, ..all_files);
    } else {
        for all_files {
            if array_find(compile_time_command_line, basename(it)) {
                array_add(*files_to_build, it);
                break;
            }
        }
    }

    assert(files_to_build.count > 0, "Couldn't find a file called '%'.", compile_time_command_line[0]);

    return files_to_build;
}

build_one :: (path: string, run_after_build := false) {
    w := compiler_create_workspace();

    using options := get_build_options(w);
    output_executable_name = basename(path);
    text_output_flags      = 0;
    emit_debug_info        = .NONE;
    output_path            = BUILD_FOLDER;

    set_build_options(options, w);

    compiler_begin_intercept(w);

    add_build_string(sprint("#load \"%\";", path), w);
    add_build_file("Main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if message.kind == .COMPLETE {
            using message_complete := cast(*Message_Complete) message;
            assert(error_code == .NONE, "Coundn't build %.", path);
            break;
        }
    }

    compiler_end_intercept(w);

    compiler_destroy_workspace(w);

    if run_after_build run_command(sprint("%\\%", output_path, output_executable_name));
}

BUILD\_FOLDER :: "build";
ASSETS_FOLDER :: "assets";
SOURCE_FOLDER :: "source";

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";
