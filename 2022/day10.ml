open Core
open Util

module Inst = struct
  type t =
    | Noop
    | Addx of int
  [@@deriving sexp]

  let cycles = function
    | Noop -> 1
    | Addx _ -> 2
  ;;
end

let parse_input input =
  String.split_lines input
  |> List.map ~f:(fun s ->
       if String.equal s "noop"
       then Inst.Noop
       else Scanf.sscanf s "addx %d" (fun d -> Inst.Addx d))
  |> List.to_array
;;

module Crt_cpu = struct
  type t =
    { instrs : Inst.t array
    ; mutable instr_index : int
    ; mutable remaining_cycles : int
    ; mutable x : int
    }
  [@@deriving sexp]

  let create instrs =
    { instrs; instr_index = 0; remaining_cycles = Inst.cycles instrs.(0); x = 1 }
  ;;

  let complete_inst t instr =
    match instr with
    | Inst.Noop -> ()
    | Addx delta -> t.x <- t.x + delta
  ;;

  let tick t =
    assert (t.remaining_cycles > 1);
    t.remaining_cycles <- t.remaining_cycles - 1;
    if t.remaining_cycles = 0
    then (
      complete_inst t t.instrs.(t.instr_index);
      t.instr_index <- t.instr_index + 1;
      if t.instr_index < Array.length t.instrs
      then t.remaining_cycles <- Inst.cycles t.instrs.(t.instr_index)
      else t.remaining_cycles <- 100_000)
  ;;
end

let solve input =
  let instrs = parse_input input in
  let cpu = Crt_cpu.create instrs in
  let key_cycles = [ 20; 60; 100; 140; 180; 220 ] in
  let part1 = ref 0 in
  let part2_chars = ref [ '\n' ] in
  List.iter (List.range ~start:`inclusive ~stop:`inclusive 1 240) ~f:(fun cycle ->
    (* For Part 1 *)
    if List.mem key_cycles cycle ~equal:Int.equal then part1 := !part1 + (cycle * cpu.x);
    (* For Part 2 *)
    let viewing_index = (cycle - 1) % 40 in
    let lit = Int.abs (cpu.x - viewing_index) < 2 in
    let pixel = if lit then '#' else '.' in
    part2_chars := pixel :: !part2_chars;
    if cycle % 40 = 0 then part2_chars := '\n' :: !part2_chars;
    Crt_cpu.tick cpu);
  print_part1 !part1;
  print_part2_s (String.of_char_list (List.rev !part2_chars))
;;
