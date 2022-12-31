open Core
open Util

module File = struct
  type t =
    { name : string
    ; size : int
    }
  [@@deriving sexp]
end

module Dir = struct
  type t =
    { name : string
    ; parent : (t option[@sexp.opaque])
    ; mutable files : File.t list
    ; mutable subdirs : t list
    ; mutable total_size : int option
    }
  [@@deriving sexp]

  let create ?parent name = { name; parent; files = []; subdirs = []; total_size = None }

  let rec compute_total_size root =
    let size_of_files = List.sum (module Int) root.files ~f:(fun file -> file.size) in
    let size_of_subdirs =
      List.sum (module Int) root.subdirs ~f:(fun subdir -> compute_total_size subdir)
    in
    let total_size = size_of_files + size_of_subdirs in
    root.total_size <- Some total_size;
    total_size
  ;;

  let rec flatten_dirs root =
    let flattened_subdirs =
      List.concat_map root.subdirs ~f:(fun subdir -> flatten_dirs subdir)
    in
    root :: flattened_subdirs
  ;;
end

module Instruction = struct
  type t =
    | Cd of string
    | Ls
    | Ls_dir of string
    | Ls_file of File.t
  [@@deriving sexp]
end

let parse_input input =
  String.split_lines input
  |> List.map ~f:(fun line ->
       if String.equal line "$ ls"
       then Instruction.Ls
       else if String.equal (String.prefix line 5) "$ cd "
       then Cd (String.drop_prefix line 5)
       else if String.equal (String.prefix line 4) "dir "
       then Ls_dir (String.drop_prefix line 4)
       else (
         let size, name = Scanf.sscanf line "%d %s" (fun s n -> s, n) in
         Ls_file { name; size }))
;;

let solve input =
  let instrs = parse_input input in
  let root = Dir.create "<root>" in
  let current_dir = ref root in
  List.iter instrs ~f:(function
    | Cd dst ->
      current_dir
        := (match dst with
            | "/" -> root
            | ".." -> Option.value_exn !current_dir.parent
            | subdir_name ->
              List.find_exn !current_dir.subdirs ~f:(fun subdir ->
                String.equal subdir.name subdir_name))
    | Ls -> ()
    | Ls_dir dir_name ->
      let subdir = Dir.create ~parent:!current_dir dir_name in
      !current_dir.subdirs <- subdir :: !current_dir.subdirs
    | Ls_file file -> !current_dir.files <- file :: !current_dir.files);
  ignore (Dir.compute_total_size root);
  let flattened = Dir.flatten_dirs root in
  let small_dirs =
    List.filter flattened ~f:(fun d -> Option.value_exn d.total_size <= 100_000)
  in
  let sum_small_dir_sizes =
    List.sum (module Int) small_dirs ~f:(fun d -> Option.value_exn d.total_size)
  in
  print_part1 sum_small_dir_sizes;
  let total_space = 70_000_000 in
  let used_space = Option.value_exn root.total_size in
  let free_space = total_space - used_space in
  let needed_space = 30_000_000 - free_space in
  let dirs_could_delete =
    List.filter flattened ~f:(fun d -> Option.value_exn d.total_size >= needed_space)
  in
  let smallest_dir_to_delete =
    list_min (List.map dirs_could_delete ~f:(fun d -> Option.value_exn d.total_size))
  in
  print_part2 smallest_dir_to_delete
;;
