open Core
open Util

module Square = struct
  type t =
    | Open
    | Wall
    | Wrap
  [@@deriving sexp, compare, hash]

  let _to_string = function
    | Open -> "."
    | Wall -> "#"
    | Wrap -> " "
  ;;
end

module Dir = struct
  type t =
    | Right
    | Down
    | Left
    | Up
  [@@deriving sexp, compare, hash]

  let _to_string = function
    | Right -> "right"
    | Down -> "down"
    | Left -> "left"
    | Up -> "up"
  ;;

  let to_dx_dy = function
    | Right -> 1, 0
    | Down -> 0, 1
    | Left -> -1, 0
    | Up -> 0, -1
  ;;

  let facing_value = function
    | Right -> 0
    | Down -> 1
    | Left -> 2
    | Up -> 3
  ;;
end

module Pt = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash]

  let create x y = { x; y }
end

module Path_elem = struct
  type t =
    | Move of int
    | Counter_clockwise
    | Clockwise
  [@@deriving sexp, compare, hash]

  let rotate t dir =
    match t, dir with
    | Move _, _ -> failwith "can't rotate move"
    | Counter_clockwise, Dir.Right -> Dir.Up
    | Counter_clockwise, Dir.Left -> Dir.Down
    | Counter_clockwise, Dir.Up -> Dir.Left
    | Counter_clockwise, Dir.Down -> Dir.Right
    | Clockwise, Dir.Right -> Dir.Down
    | Clockwise, Dir.Left -> Dir.Up
    | Clockwise, Dir.Up -> Dir.Right
    | Clockwise, Dir.Down -> Dir.Left
  ;;
end

let parse_path input =
  String.substr_replace_all input ~pattern:"L" ~with_:"\nL\n"
  |> String.substr_replace_all ~pattern:"R" ~with_:"\nR\n"
  |> String.strip
  |> String.split_lines
  |> List.map ~f:(function
       | "L" -> Path_elem.Counter_clockwise
       | "R" -> Path_elem.Clockwise
       | s -> Path_elem.Move (Int.of_string s))
;;

let parse_maze input =
  let lines = String.split_lines input in
  let line_lengths = List.map lines ~f:String.length in
  let width = list_max line_lengths in
  let height = List.length lines in
  let chars = Grid.create ~dimx:width ~dimy:height ' ' in
  List.iteri lines ~f:(fun y line ->
    List.iteri (String.to_list line) ~f:(fun x ch -> chars.(x).(y) <- ch));
  Grid.map chars ~f:(function
    | ' ' -> Square.Wrap
    | '.' -> Square.Open
    | '#' -> Square.Wall
    | _ -> failwith "Invalid maze char")
;;

let parse input =
  let maze, path =
    String.substr_replace_all input ~pattern:"\n\n" ~with_:"$"
    |> String.lsplit2_exn ~on:'$'
  in
  parse_maze maze, parse_path path
;;

let find_starting_spot maze =
  let starting_x = ref None in
  for x = 0 to Grid.width maze - 1 do
    match !starting_x, maze.(x).(0) with
    | None, Square.Open -> starting_x := Some x
    | _ -> ()
  done;
  Pt.create (Option.value_exn !starting_x) 0
;;

let first_non_empty maze sx sy dir length =
  let first = ref None in
  let dx, dy = Dir.to_dx_dy dir in
  for d = 1 to length do
    let x = sx + (dx * d) in
    let y = sy + (dy * d) in
    match !first, maze.(x).(y) with
    | None, Square.Wall | None, Square.Open -> first := Some (Pt.create x y)
    | _ -> ()
  done;
  Option.value_exn !first
;;

let first_in_row maze row = first_non_empty maze (-1) row Dir.Right (Grid.width maze)

let last_in_row maze row =
  first_non_empty maze (Grid.width maze) row Dir.Left (Grid.width maze)
;;

let first_in_col maze col = first_non_empty maze col (-1) Dir.Down (Grid.height maze)

let last_in_col maze col =
  first_non_empty maze col (Grid.height maze) Dir.Up (Grid.height maze)
;;

let simple_wrap maze x y dir =
  match dir with
  | Dir.Right -> first_in_row maze y, Dir.Right
  | Left -> last_in_row maze y, Dir.Left
  | Down -> first_in_col maze x, Dir.Down
  | Up -> last_in_col maze x, Dir.Up
;;

(* Example
let cube_side = 4

let cube_wrap maze x y dir =
  let s0 = 0 * cube_side in
  let s1 = 1 * cube_side in
  let s2 = 2 * cube_side in
  let s3 = 3 * cube_side in
  (* let s4 = 4 * cube_side in *)
  match dir with
  | Dir.Right ->
    let height = y % cube_side in
    let flipped_height = cube_side - 1 - height in
    (match y / cube_side with
     | 0 -> last_in_row maze (s2 + flipped_height), Dir.Left
     | 1 -> first_in_col maze (s3 + flipped_height), Dir.Down
     | 2 -> last_in_row maze (s0 + flipped_height), Dir.Left
     | _ -> failwith "invalid height when going off right side")
  | Left ->
    let height = y % cube_side in
    let flipped_height = cube_side - 1 - height in
    (match y / cube_side with
     | 0 -> first_in_col maze (s1 + height), Dir.Down
     | 1 -> last_in_col maze (s3 + flipped_height), Dir.Up
     | 2 -> last_in_col maze (s1 + flipped_height), Dir.Up
     | _ -> failwith "invalid height when going off right side")
  | Down ->
    let width = x % cube_side in
    let flipped_width = cube_side - 1 - width in
    (match x / cube_side with
     | 0 -> last_in_col maze (s2 + flipped_width), Dir.Up
     | 1 -> first_in_row maze (s2 + flipped_width), Dir.Right
     | 2 -> last_in_col maze (s0 + flipped_width), Dir.Up
     | 3 -> first_in_row maze (s1 + flipped_width), Dir.Right
     | _ -> failwith "invalid width when going off right side")
  | Up ->
    let width = x % cube_side in
    let flipped_width = cube_side - 1 - width in
    (match x / cube_side with
     | 0 -> first_in_col maze (s2 + flipped_width), Dir.Down
     | 1 -> first_in_row maze (s0 + width), Dir.Right
     | 2 -> first_in_col maze (s0 + flipped_width), Dir.Down
     | 3 -> last_in_row maze (s2 + flipped_width), Dir.Left
     | _ -> failwith "invalid width when going off right side")
;;
*)

let cube_side = 50

(*

            0000000  1111111   222222

                    +F-------+-------G+
0                   |        |        |
0                   |        |        |
0                   |        |        |
0                   E        |        C
                    +--------+-B------+
1                   |        B
1                   |        |
1                   A        |
1                   |        |
           +------A-+--------+
2          E        |        C
2          |        |        |
2          |        |        |
2          |        |        |
           +--------+D-------+
3          F        D
3          |        |
3          |        |
3          |        |
           +------G-+

*)
let cube_wrap maze x y dir =
  let s0 = 0 * cube_side in
  let s1 = 1 * cube_side in
  let s2 = 2 * cube_side in
  let s3 = 3 * cube_side in
  match dir with
  | Dir.Right ->
    let height = y % cube_side in
    let flipped_height = cube_side - 1 - height in
    (match y / cube_side with
     | 0 -> last_in_row maze (s2 + flipped_height), Dir.Left (* C *)
     | 1 -> last_in_col maze (s2 + height), Dir.Up (* B *)
     | 2 -> last_in_row maze (s0 + flipped_height), Dir.Left (* C *)
     | 3 -> last_in_col maze (s2 + height), Dir.Up (* D *)
     | _ -> failwith "invalid height when going off right side")
  | Left ->
    let height = y % cube_side in
    let flipped_height = cube_side - 1 - height in
    (match y / cube_side with
     | 0 -> first_in_row maze (s2 + flipped_height), Dir.Right (* E *)
     | 1 -> first_in_col maze (s0 + height), Dir.Down (* A *)
     | 2 -> first_in_row maze (s0 + flipped_height), Dir.Right (* E *)
     | 3 -> first_in_col maze (s1 + height), Dir.Down (* F *)
     | _ -> failwith "invalid height when going off right side")
  | Down ->
    let width = x % cube_side in
    let _flipped_width = cube_side - 1 - width in
    (match x / cube_side with
     | 0 -> first_in_col maze (s2 + width), Dir.Down (* G *)
     | 1 -> last_in_row maze (s3 + width), Dir.Left (* D *)
     | 2 -> last_in_row maze (s1 + width), Dir.Left (* B *)
     | _ -> failwith "invalid width when going off right side")
  | Up ->
    let width = x % cube_side in
    let _flipped_width = cube_side - 1 - width in
    (match x / cube_side with
     | 0 -> first_in_row maze (s1 + width), Dir.Right (* A *)
     | 1 -> first_in_row maze (s3 + width), Dir.Right (* F *)
     | 2 -> last_in_col maze (s0 + width), Dir.Up (* G *)
     | _ -> failwith "invalid width when going off right side")
;;

let next_in_dir maze pos dir ~on_cube =
  let { Pt.x; y } = pos in
  let dx, dy = Dir.to_dx_dy dir in
  let x = x + dx in
  let y = y + dy in
  let wrap () = if on_cube then cube_wrap maze x y dir else simple_wrap maze x y dir in
  if Grid.in_range maze ~x ~y
  then (
    match maze.(x).(y) with
    | Square.Wrap -> wrap ()
    | _ -> Pt.create x y, dir)
  else wrap ()
;;

let move_n_steps maze pos dir n ~on_cube =
  let pos = ref pos in
  let dir = ref dir in
  for _ = 1 to n do
    let next_pos, next_dir = next_in_dir maze !pos !dir ~on_cube in
    match maze.(next_pos.x).(next_pos.y) with
    | Square.Open ->
      (*
      printf
        "  Moved to (%d, %d), now facing %s (%d, %d)\n"
        next_pos.x
        next_pos.y
        (Dir.to_string next_dir)
        (fst (Dir.to_dx_dy next_dir))
        (snd (Dir.to_dx_dy next_dir));
        *)
      pos := next_pos;
      dir := next_dir
    | Square.Wall -> ()
    | Square.Wrap -> failwith "next in dir shouldn't be wrap"
  done;
  !pos, !dir
;;

let solve input =
  let maze, path = parse input in
  let solve ~on_cube =
    let pos = ref (find_starting_spot maze) in
    let dir = ref Dir.Right in
    List.iter path ~f:(fun p ->
      (* print_s [%sexp (!pos : Pt.t)]; *)
      (* print_s [%sexp (p : Path_elem.t)]; *)
      match p with
      | Path_elem.Move n ->
        let new_pos, new_dir = move_n_steps maze !pos !dir n ~on_cube in
        pos := new_pos;
        dir := new_dir
      | _ -> dir := Path_elem.rotate p !dir
      (*
      printf
        "  Now facing %s (%d, %d)\n"
        (Dir.to_string !dir)
        (fst (Dir.to_dx_dy !dir))
        (snd (Dir.to_dx_dy !dir)) *));
    let row = !pos.y + 1 in
    let col = !pos.x + 1 in
    let facing = Dir.facing_value !dir in
    (1000 * row) + (4 * col) + facing
  in
  print_part1 (solve ~on_cube:false);
  print_part2 (solve ~on_cube:true)
;;

(* Too low: 189051 *)
