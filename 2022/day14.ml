open Core
open Util

(* Given a list [ x1; x2; x3; x4; ...; xn-1; xn ] ,
   returns a list of adjacent tuples:
     [ x1, x2 ; x2 , x3 ; ... ; xn-1, xn ]
*)
let rec slices_of_2 = function
  | [] -> []
  | [ _ ] -> []
  | hd1 :: hd2 :: tl -> (hd1, hd2) :: slices_of_2 (hd2 :: tl)
;;

module Point = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash]

  let create x y = { x; y }
end

module Rock_structure = struct
  type t = Point.t list [@@deriving sexp, compare, hash]

  let parse s =
    String.substr_replace_all s ~pattern:" -> " ~with_:"$"
    |> String.split ~on:'$'
    |> List.map ~f:(fun s -> Scanf.sscanf s "%d,%d" Point.create)
  ;;

  let step_size i1 i2 =
    match Int.sign (i2 - i1) with
    | Sign.Zero -> 0
    | Pos -> 1
    | Neg -> -1
  ;;

  let all_points t =
    let points =
      List.concat_map (slices_of_2 t) ~f:(fun (p1, p2) ->
        let { Point.x = x1; y = y1 } = p1 in
        let { Point.x = x2; y = y2 } = p2 in
        let steps = Int.max (Int.abs (x1 - x2)) (Int.abs (y1 - y2)) in
        let dx = step_size x1 x2 in
        let dy = step_size y1 y2 in
        List.map (List.range 1 ~stop:`inclusive steps) ~f:(fun num_steps ->
          Point.create (x1 + (dx * num_steps)) (y1 + (dy * num_steps))))
    in
    List.hd_exn t :: points
  ;;
end

let solve input =
  let rock_structures = String.split_lines input |> List.map ~f:Rock_structure.parse in
  let all_rocks = List.concat_map rock_structures ~f:Rock_structure.all_points in
  let min_x = list_min (List.map all_rocks ~f:(fun pt -> pt.x)) in
  let max_x = list_max (List.map all_rocks ~f:(fun pt -> pt.x)) in
  let max_y = list_max (List.map all_rocks ~f:(fun pt -> pt.y)) + 2 in
  let occupied_spaces = Hash_set.of_list (module Point) all_rocks in
  let place_sand () =
    let sx = ref 500
    and sy = ref 0
    and is_placed = ref false in
    while (not !is_placed) && !sy < max_y do
      let down = Point.create !sx (!sy + 1) in
      let down_left = Point.create (!sx - 1) (!sy + 1) in
      let down_right = Point.create (!sx + 1) (!sy + 1) in
      if not (Hash_set.mem occupied_spaces down)
      then (
        sx := down.x;
        sy := down.y)
      else if not (Hash_set.mem occupied_spaces down_left)
      then (
        sx := down_left.x;
        sy := down_left.y)
      else if not (Hash_set.mem occupied_spaces down_right)
      then (
        sx := down_right.x;
        sy := down_right.y)
      else is_placed := true
    done;
    if !is_placed then Hash_set.add occupied_spaces (Point.create !sx !sy);
    !is_placed
  in
  let num_grains_placed = ref 0 in
  while place_sand () do
    num_grains_placed := !num_grains_placed + 1
  done;
  print_part1 !num_grains_placed;
  (* Place floor for part 2 *)
  let min_x = Int.min 500 min_x - max_y - 10 in
  let max_x = Int.max 500 max_x + max_y + 10 in
  List.iter (List.range min_x max_x) ~f:(fun x ->
    Hash_set.add occupied_spaces (Point.create x max_y));
  let start = Point.create 500 0 in
  while not (Hash_set.mem occupied_spaces start) do
    ignore (place_sand ());
    num_grains_placed := !num_grains_placed + 1
  done;
  print_part2 !num_grains_placed
;;
