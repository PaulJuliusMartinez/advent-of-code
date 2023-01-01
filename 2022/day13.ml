open Core
open Util

module Packet = struct
  type t =
    | P_int of int
    | P_list of t list
  [@@deriving sexp]

  let parse s =
    let chars = ref (String.to_list s) in
    let stack : t list Stack.t = Stack.create () in
    Stack.push stack [];
    while not (List.is_empty !chars) do
      match List.hd_exn !chars with
      | '[' ->
        Stack.push stack [];
        chars := List.tl_exn !chars
      | ']' ->
        let completed = List.rev (Stack.pop_exn stack) in
        let parent_packet_list = Stack.pop_exn stack in
        Stack.push stack (P_list completed :: parent_packet_list);
        chars := List.tl_exn !chars
      | ',' -> chars := List.tl_exn !chars
      | _ ->
        let digit_chars, rest = List.split_while !chars ~f:Char.is_digit in
        chars := rest;
        let num = Int.of_string (String.of_char_list digit_chars) in
        let top = Stack.pop_exn stack in
        Stack.push stack (P_int num :: top)
    done;
    P_list (Stack.pop_exn stack)
  ;;

  let rec compare p1 p2 =
    match p1, p2 with
    | P_int i1, P_int i2 -> Int.compare i1 i2
    | P_int _, P_list _ -> compare (P_list [ p1 ]) p2
    | P_list _, P_int _ -> compare p1 (P_list [ p2 ])
    | P_list l1, P_list l2 ->
      (match l1, l2 with
       | [], [] -> 0
       | [], _ -> -1
       | _, [] -> 1
       | hd1 :: tl1, hd2 :: tl2 ->
         (match compare hd1 hd2 with
          | 0 -> compare (P_list tl1) (P_list tl2)
          | order -> order))
  ;;

  let equal p1 p2 = compare p1 p2 = 0
end

let solve input =
  let packet_pairs =
    String.substr_replace_all input ~pattern:"\n\n" ~with_:"$"
    |> String.split ~on:'$'
    |> List.map ~f:(fun packets ->
         let packet_pairs = String.split_lines packets |> List.map ~f:Packet.parse in
         List.nth_exn packet_pairs 0, List.nth_exn packet_pairs 1)
  in
  let in_order_indexes =
    List.filter_mapi packet_pairs ~f:(fun i (p1, p2) ->
      if Packet.compare p1 p2 < 0 then Some (i + 1) else None)
  in
  print_part1 (list_sum in_order_indexes);
  let divider_packet1 = Packet.parse "[[2]]" in
  let divider_packet2 = Packet.parse "[[6]]" in
  let all_packets =
    divider_packet1
    :: divider_packet2
    :: List.concat_map packet_pairs ~f:(fun (p1, p2) -> [ p1; p2 ])
  in
  let sorted_packets = List.sort all_packets ~compare:Packet.compare in
  let key1 =
    1 + fst (List.findi_exn sorted_packets ~f:(fun _ p -> Packet.equal p divider_packet1))
  in
  let key2 =
    1 + fst (List.findi_exn sorted_packets ~f:(fun _ p -> Packet.equal p divider_packet2))
  in
  print_part2 (key1 * key2)
;;
