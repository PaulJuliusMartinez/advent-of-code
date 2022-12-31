open Core
open Util

let parse_input input =
  let lines = String.split_lines input in
  let width = String.length (List.hd_exn lines) in
  let height = List.length lines in
  let tree_heights = Array.make_matrix ~dimx:width ~dimy:height 0 in
  List.iteri lines ~f:(fun y line ->
    List.iteri (String.to_list line) ~f:(fun x ch ->
      tree_heights.(x).(y) <- Int.of_string (String.of_char ch)));
  let visibilities = Array.make_matrix ~dimx:width ~dimy:height false in
  tree_heights, visibilities
;;

let check_if_visible_from_left row visibility =
  let max_height = ref (-1) in
  Array.iteri row ~f:(fun i height ->
    if height > !max_height
    then (
      visibility.(i) <- true;
      max_height := height))
;;

let compute_left_and_right_visibilities tree_grid visibilities =
  Array.iteri tree_grid ~f:(fun i row ->
    let visibility_row = visibilities.(i) in
    check_if_visible_from_left row visibility_row;
    Array.rev_inplace row;
    Array.rev_inplace visibility_row;
    check_if_visible_from_left row visibility_row;
    (* Reverse again to leave grid unchanged. *)
    Array.rev_inplace row;
    Array.rev_inplace visibility_row)
;;

let scenic_score tree_grid ~x ~y =
  let width = Array.length tree_grid in
  let height = Array.length tree_grid.(0) in
  let deltas = [ 0, 1; 0, -1; 1, 0; -1, 0 ] in
  (* down up right left *)
  let in_range xx yy = 0 <= xx && xx < width && 0 <= yy && yy < height in
  let tree_house_height = tree_grid.(x).(y) in
  let viewing_distances =
    List.map deltas ~f:(fun delta ->
      let dx, dy = delta in
      let can_see_further = ref true in
      let num_seen = ref 0 in
      let vx = ref (x + dx) in
      let vy = ref (y + dy) in
      while in_range !vx !vy && !can_see_further do
        num_seen := !num_seen + 1;
        if tree_grid.(!vx).(!vy) >= tree_house_height
        then can_see_further := false
        else (
          vx := !vx + dx;
          vy := !vy + dy)
      done;
      !num_seen)
  in
  List.fold viewing_distances ~init:1 ~f:Int.( * )
;;

let count_num_visible_trees tree_grid visibilities =
  compute_left_and_right_visibilities tree_grid visibilities;
  let tree_grid = Option.value_exn (Array.transpose tree_grid) in
  let visibilities = Option.value_exn (Array.transpose visibilities) in
  compute_left_and_right_visibilities tree_grid visibilities;
  Array.sum
    (module Int)
    visibilities
    ~f:(fun visibility_row -> Array.count visibility_row ~f:Fn.id)
;;

let solve input =
  let tree_grid, visibilities = parse_input input in
  print_part1 (count_num_visible_trees tree_grid visibilities);
  let max_scenic_score =
    array_max
      (Array.mapi tree_grid ~f:(fun y row ->
         array_max (Array.mapi row ~f:(fun x _ -> scenic_score tree_grid ~x ~y))))
  in
  print_part2 max_scenic_score
;;
