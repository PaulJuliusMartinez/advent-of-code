open Core
open Util

let parse_input input =
  let tree_heights =
    Grid.of_puzzle_input input ~f:(fun ch -> Int.of_string (String.of_char ch))
  in
  let visibilities = Grid.of_same_size tree_heights false in
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

let scenic_score tree_grid ~x ~y _ =
  let deltas = [ 0, 1; 0, -1; 1, 0; -1, 0 ] in
  (* down up right left *)
  let in_range x y = Grid.in_range tree_grid ~x ~y in
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
  list_product viewing_distances
;;

let count_num_visible_trees tree_grid visibilities =
  compute_left_and_right_visibilities tree_grid visibilities;
  let tree_grid = Option.value_exn (Array.transpose tree_grid) in
  let visibilities = Option.value_exn (Array.transpose visibilities) in
  compute_left_and_right_visibilities tree_grid visibilities;
  Grid.count visibilities ~f:Fn.id
;;

let solve input =
  let tree_grid, visibilities = parse_input input in
  print_part1 (count_num_visible_trees tree_grid visibilities);
  let max_scenic_score = Grid.maxc_of_int tree_grid ~f:(scenic_score tree_grid) in
  print_part2 max_scenic_score
;;
