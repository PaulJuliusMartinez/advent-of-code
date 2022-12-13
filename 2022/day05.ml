open Core
open Util

(* Input looks like this:
   >      [D]
   >  [N] [C]
   >  [Z] [M] [P]
   >   1   2   3

   We take the lines, and transpose them to get something like this:
   >  [[
   >  NZ1
   >  ]]
   >
   > [[[
   > DCM2
   > ]]]
   > ...

   From there we filter out the blank lines, and the lines with '[' or ']'.
   Through in a reverse or two (who knows) to get it to work correctly.
*)

let parse input =
  let lines = String.split_lines input in
  let stack_lines = List.take_while lines ~f:(fun s -> not (String.equal s "")) in
  let transposed =
    List.map stack_lines ~f:String.to_list
    |> List.transpose_exn
    |> List.map ~f:String.of_char_list
    |> List.filter ~f:(fun s ->
           (not (String.equal (String.strip s) ""))
           && (not (String.is_suffix s ~suffix:"[ "))
           && not (String.is_suffix s ~suffix:"] "))
    |> List.map ~f:String.strip |> List.map ~f:String.to_list |> List.to_array
  in
  let instructions = List.drop lines (List.length stack_lines + 1) in
  let instructions =
    List.map instructions ~f:(fun s ->
        Scanf.sscanf s "move %d from %d to %d" (fun a b c -> (a, b - 1, c - 1)))
  in
  (transposed, instructions)
;;

(* Unsure of runtime of OCaml list operations, so not sure if this is
   accidentally O(n^2). *)
let move_between ~stacks ~count ~from ~too ~rev =
  let from_stack = Array.get stacks from in
  let popped = List.take from_stack count in
  let to_stack = Array.get stacks too in
  Array.set stacks from (List.drop from_stack count);
  let moved = if rev then List.rev popped else popped in
  Array.set stacks too (List.concat [ moved; to_stack ])
;;

(*
let print_stacks stacks =
  print_endline "Stacks:";
  Array.iter stacks ~f:(fun l -> print_endline (String.of_char_list l))
;;
*)

let solve input =
  let stacks, instructions = parse input in
  List.iter instructions ~f:(fun (count, from, too) ->
      (*
      print_stacks stacks;
      print_endline
        ("move count (" ^ Int.to_string count ^ ") from " ^ Int.to_string from ^ " to "
       ^ Int.to_string too);
       *)
      move_between ~stacks ~count ~from ~too ~rev:true);
  let tops = String.of_char_list (Array.to_list (Array.map stacks ~f:List.hd_exn)) in
  print_part1_s tops;
  let stacks, instructions = parse input in
  List.iter instructions ~f:(fun (count, from, too) ->
      move_between ~stacks ~count ~from ~too ~rev:false);
  let tops = String.of_char_list (Array.to_list (Array.map stacks ~f:List.hd_exn)) in
  print_part2_s tops
;;
