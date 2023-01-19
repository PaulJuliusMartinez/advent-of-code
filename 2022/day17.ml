open Core
open Util

module Loop_seq = struct
  type 'a t =
    { elems : 'a array
    ; mutable index : int
    }

  let create elems = { elems = Array.of_list elems; index = 0 }

  let next s =
    if s.index = Array.length s.elems then s.index <- 0;
    let n = s.elems.(s.index) in
    s.index <- s.index + 1;
    n
  ;;

  let index t = t.index
end

(*
####

.#.
###
.#.

..#
..#
###

#
#
#
#

##
##
*)

(*
.......
.##....
.##....
..#....
..#....
..#....
..#....
..#....
..#....
###....
.#.....
###....
.#.....
####...
*)

let line = [| 0, 0; 1, 0; 2, 0; 3, 0 |]
let plus = [| 1, 0; 0, 1; 1, 1; 2, 1; 1, 2 |]
let ell = [| 0, 0; 1, 0; 2, 0; 2, 1; 2, 2 |]
let bar = [| 0, 0; 0, 1; 0, 2; 0, 3 |]
let box = [| 0, 0; 1, 0; 0, 1; 1, 1 |]
let rock_cycle = [ line; plus; ell; bar; box ]
let max_relevant_rows = 15 (* Really 13, but let's do 15 to be safe *)

module Push = struct
  type t =
    | Left
    | Right
  [@@deriving sexp, compare, hash]

  let parse s =
    String.strip s
    |> String.to_list
    |> List.map ~f:(function
         | '<' -> Left
         | '>' -> Right
         | _ -> failwith "unknown char")
  ;;
end

let max_rock_height = 4
let offset = 3

module Board = struct
  type t =
    { rows : bool Array.t Array.t
    ; width : int
    ; mutable first_clear_row : int
    }
  [@@deriving fields]

  let create ~width ~num_rocks =
    let max_height = (num_rocks * max_rock_height) + offset + max_rock_height in
    let rows = Array.init max_height ~f:(fun _ -> Array.create ~len:width false) in
    { rows; width; first_clear_row = 0 }
  ;;

  let update_coords rock ~dx ~dy = Array.map rock ~f:(fun (x, y) -> x + dx, y + dy)
  let init_rock t rock = update_coords rock ~dx:2 ~dy:(t.first_clear_row + offset)
  let any_collisions t rock = Array.exists rock ~f:(fun (x, y) -> t.rows.(y).(x))
  let place_rock t rock = Array.iter rock ~f:(fun (x, y) -> t.rows.(y).(x) <- true)

  let x_in_bounds t rock =
    not (Array.exists rock ~f:(fun (x, _) -> x < 0 || x >= t.width))
  ;;

  let try_push t rock push =
    let dx =
      match push with
      | Push.Left -> -1
      | Right -> 1
    in
    let pushed_rock = update_coords rock ~dx ~dy:0 in
    if (not (x_in_bounds t pushed_rock)) || any_collisions t pushed_rock
    then rock
    else pushed_rock
  ;;

  let try_drop t rock =
    if Array.exists rock ~f:(fun (_, y) -> y = 0)
    then rock, false
    else (
      let dropped_rock = update_coords rock ~dx:0 ~dy:(-1) in
      if any_collisions t dropped_rock then rock, false else dropped_rock, true)
  ;;

  let update_first_clear_row t rock =
    Array.iter rock ~f:(fun (_, y) ->
      if y >= t.first_clear_row then t.first_clear_row <- y + 1)
  ;;

  let drop_rock t rock pushes =
    let rock = ref (init_rock t rock) in
    let fell = ref true in
    while !fell do
      rock := try_push t !rock (Loop_seq.next pushes);
      let maybe_dropped_rock, did_fall = try_drop t !rock in
      rock := maybe_dropped_rock;
      fell := did_fall
    done;
    place_rock t !rock;
    update_first_clear_row t !rock
  ;;

  let top_rows_state t =
    let y = t.first_clear_row in
    List.range 1 ~stop:`inclusive max_relevant_rows
    |> List.map ~f:(fun dy ->
         let y = y - dy in
         if y < 0
         then "#######"
         else
           Array.map t.rows.(y) ~f:(fun occupied -> if occupied then '#' else '.')
           |> Array.to_list
           |> String.of_char_list)
    |> String.concat ~sep:"\n"
  ;;
end

module Game_state = struct
  type t =
    { top_rows : string
    ; rock_index : int
    ; push_index : int
    }
  [@@deriving sexp, compare, hash]
end

let solve input =
  let pushes = Loop_seq.create (Push.parse input) in
  let rocks = Loop_seq.create rock_cycle in
  let num_rocks = 2022 in
  let board = Board.create ~width:7 ~num_rocks in
  for _ = 1 to num_rocks do
    let rock = Loop_seq.next rocks in
    Board.drop_rock board rock pushes
  done;
  print_part1 board.first_clear_row;
  (* Re-initialize rocks and pushes!! *)
  let pushes = Loop_seq.create (Push.parse input) in
  let rocks = Loop_seq.create rock_cycle in
  let seen_states = Hashtbl.create (module Game_state) in
  let board = Board.create ~width:7 ~num_rocks in
  let get_state () =
    { Game_state.top_rows = Board.top_rows_state board
    ; rock_index = Loop_seq.index rocks
    ; push_index = Loop_seq.index pushes
    }
  in
  let rocks_dropped = ref 0 in
  let store_state () =
    let clear_row = Board.first_clear_row board in
    let rocks_dropped = !rocks_dropped in
    let curr_state = get_state () in
    match Hashtbl.add seen_states ~key:curr_state ~data:(clear_row, rocks_dropped) with
    | `Ok -> false
    | `Duplicate -> true
  in
  let seen_last_state = ref (store_state ()) in
  while not !seen_last_state do
    let rock = Loop_seq.next rocks in
    Board.drop_rock board rock pushes;
    incr rocks_dropped;
    seen_last_state := store_state ()
  done;
  let first_clear_row, num_rocks = Hashtbl.find_exn seen_states (get_state ()) in
  let cycle_length = !rocks_dropped - num_rocks in
  let cycle_height = Board.first_clear_row board - first_clear_row in
  let rocks_to_drop = 1_000_000_000_000 in
  let rocks_left_to_drop = rocks_to_drop - !rocks_dropped in
  let num_full_cycles = rocks_left_to_drop / cycle_length in
  let remaining_rocks = rocks_left_to_drop - (num_full_cycles * cycle_length) in
  for _ = 1 to remaining_rocks do
    let rock = Loop_seq.next rocks in
    Board.drop_rock board rock pushes
  done;
  let current_height = Board.first_clear_row board in
  let final_height = current_height + (num_full_cycles * cycle_height) in
  print_part2 final_height
;;
