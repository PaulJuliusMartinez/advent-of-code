open Core
open Util

let first_n_are_distinct chars n =
  let set = Char.Hash_set.of_list (List.take chars n) in
  Hash_set.count set ~f:(fun _ -> true) = n
;;

let solve input =
  let chars = String.to_list input in
  let c1 = ref (List.hd_exn chars) in
  let c2 = ref (List.hd_exn (List.tl_exn chars)) in
  let c3 = ref (List.hd_exn (List.tl_exn (List.tl_exn chars))) in
  let rest = List.tl_exn (List.tl_exn (List.tl_exn chars)) in
  let index, _ =
    List.findi_exn rest ~f:(fun _ ch ->
        if Char.(
             !c1 <> !c2 && !c2 <> !c3 && !c3 <> ch && !c1 <> !c3 && !c1 <> ch && !c2 <> ch)
        then true
        else (
          c1 := !c2;
          c2 := !c3;
          c3 := ch;
          false))
  in
  print_part1 (index + 4);
  let count = ref 14 in
  let rest = ref chars in
  while not (first_n_are_distinct !rest 14) do
    rest := List.tl_exn !rest;
    count := !count + 1
  done;
  print_part2 !count
;;
