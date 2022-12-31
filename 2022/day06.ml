open Core
open Util

let first_n_are_distinct chars n =
  let set = Char.Hash_set.of_list (List.take chars n) in
  Hash_set.length set = n
;;

let index_of_first_n_uniq chars n =
  let count = ref n in
  let rest = ref chars in
  while not (first_n_are_distinct !rest n) do
    rest := List.tl_exn !rest;
    count := !count + 1
  done;
  !count
;;

let solve input =
  let chars = String.to_list input in
  print_part1 (index_of_first_n_uniq chars 4);
  print_part2 (index_of_first_n_uniq chars 14)
;;
