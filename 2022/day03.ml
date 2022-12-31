open Core
open Util

let lowercase_offset = Char.to_int 'a' - 1
let uppercase_offset = Char.to_int 'A' - 1

let priority item =
  if Char.is_lowercase item
  then Char.to_int item - lowercase_offset
  else Char.to_int item - uppercase_offset + 26
;;

let shared_item rucksack =
  let items = String.to_list rucksack in
  let num_items = List.length items in
  let bag1 = Char.Hash_set.of_list (List.take items (num_items / 2)) in
  let bag2 = Char.Hash_set.of_list (List.drop items (num_items / 2)) in
  List.hd_exn (Hash_set.to_list (Hash_set.inter bag1 bag2))
;;

let in_groups_of_n l n =
  let rec in_groups_of_n l n groups =
    if List.is_empty l
    then groups
    else (
      let next_group = List.take l n in
      let rest = List.drop l n in
      in_groups_of_n rest n (next_group :: groups))
  in
  let grouped = in_groups_of_n l n [] in
  List.rev grouped
;;

let badge_priority group =
  (*
  let bag_items = List.map group ~f:(fun l -> Char.Hash_set.of_list (String.to_list l)) in
  let badge_items = List.reduce_exn ~f:Hash_set.inter bag_items in
  priority (List.hd_exn (Hash_set.to_list badge_items))
  *)
  group
  |> List.map ~f:String.to_list
  |> List.map ~f:Char.Hash_set.of_list
  |> List.reduce_exn ~f:Hash_set.inter
  |> Hash_set.to_list
  |> List.hd_exn
  |> priority
;;

let solve input =
  let lines = String.split_lines input in
  let sum_priorities =
    List.sum (module Int) ~f:(fun l -> shared_item l |> priority) lines
  in
  print_part1 sum_priorities;
  let elf_groups = in_groups_of_n lines 3 in
  let sum_badges = List.sum (module Int) ~f:badge_priority elf_groups in
  print_part2 sum_badges
;;
