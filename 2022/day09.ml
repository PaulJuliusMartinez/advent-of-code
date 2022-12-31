open Core
open Util

let parse_input input =
  String.split_lines input
  |> List.map ~f:(fun s ->
       Scanf.sscanf s "%c %d" (fun dir steps ->
         let delta =
           match dir with
           | 'R' -> 1, 0
           | 'L' -> -1, 0
           | 'U' -> 0, 1
           | 'D' -> 0, -1
           | _ -> assert false
         in
         delta, steps))
;;

module Point = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving compare, sexp, hash]
end

module Rope = struct
  type t = (int * int) array

  let create ~len = Array.create ~len (0, 0)

  let follow hx hy tx ty =
    let dtx, dty =
      match hx - tx, hy - ty with
      | 2, 0 -> 1, 0
      | 2, 1 -> 1, 1
      | 2, -1 -> 1, -1
      | 2, 2 -> 1, 1
      | -2, 0 -> -1, 0
      | -2, 1 -> -1, 1
      | -2, -1 -> -1, -1
      | -2, -2 -> -1, -1
      | -1, 2 -> -1, 1
      | 0, 2 -> 0, 1
      | 1, 2 -> 1, 1
      | -2, 2 -> -1, 1
      | -1, -2 -> -1, -1
      | 0, -2 -> 0, -1
      | 1, -2 -> 1, -1
      | 2, -2 -> 1, -1
      | _ -> 0, 0
    in
    tx + dtx, ty + dty
  ;;

  let move_head t dx dy =
    let px = ref 0
    and py = ref 0 in
    Array.mapi t ~f:(fun i (x, y) ->
      let nx, ny = if i = 0 then x + dx, y + dy else follow !px !py x y in
      px := nx;
      py := ny;
      nx, ny)
  ;;
end

let solve input =
  let instrs =
    parse_input input
    |> List.to_array
    |> Array.concat_map ~f:(fun (delta, count) -> Array.create delta ~len:count)
  in
  let solve tail_length =
    let tail_positions = Hash_set.create (module Point) in
    Hash_set.add tail_positions { x = 0; y = 0 };
    let rope : Rope.t ref = ref (Rope.create ~len:tail_length) in
    Array.iter instrs ~f:(fun (dx, dy) ->
      rope := Rope.move_head !rope dx dy;
      let tx, ty = Array.last !rope in
      Hash_set.add tail_positions { x = tx; y = ty });
    Hash_set.length tail_positions
  in
  print_part1 (solve 2);
  print_part2 (solve 10)
;;
