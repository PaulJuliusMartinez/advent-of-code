open Core
open Util

let break_up_by_empty_lines lines =
  let f line (grouped_nums, current_nums) =
    if String.equal line ""
    then (current_nums :: grouped_nums, [])
    else (grouped_nums, Int.of_string line :: current_nums)
  in
  let grouped, last = List.fold_right lines ~init:([], []) ~f in
  (* With fold instead of fold_right, have to reverse everything with:
     List.map (List.rev (last :: grouped)) ~f:List.rev *)
  last :: grouped
;;

let sum_list = List.sum (module Int) ~f:Fn.id

let solve input =
  let lines = String.split_lines input in
  let grouped_counts = break_up_by_empty_lines lines in
  let elf_total_calories = List.map grouped_counts ~f:sum_list in
  let most_calories =
    Option.value_exn (List.max_elt elf_total_calories ~compare:Int.compare)
  in
  print_part1 most_calories;
  let elves_sorted_calories = List.sort elf_total_calories ~compare:Int.descending in
  let top_3_elves = List.take elves_sorted_calories 3 in
  let sum_top_3 = sum_list top_3_elves in
  print_part2 sum_top_3
;;
