open Core
open Util

let parse input =
  List.map input ~f:(fun s ->
      let first, second = String.lsplit2_exn ~on:',' s in
      let s1, e1 = String.lsplit2_exn ~on:'-' first in
      let s2, e2 = String.lsplit2_exn ~on:'-' second in
      ((Int.of_string s1, Int.of_string e1), (Int.of_string s2, Int.of_string e2)))
;;

let fully_overlaps ((s1, e1), (s2, e2)) = (s1 <= s2 && e2 <= e1) || (s2 <= s1 && e1 <= e2)

let overlaps_at_all ((s1, e1), (s2, e2)) =
  (s1 <= s2 && s2 <= e1)
  || (s1 <= e2 && e2 <= e1)
  || (s2 <= s1 && s1 <= e2)
  || (s2 <= e1 && e1 <= e2)
;;

let solve input =
  let ranges = parse (String.split_lines input) in
  let num_overlaps = List.count ranges ~f:fully_overlaps in
  print_part1 num_overlaps;
  let num_partial_overlaps = List.count ranges ~f:overlaps_at_all in
  print_part2 num_partial_overlaps
;;
