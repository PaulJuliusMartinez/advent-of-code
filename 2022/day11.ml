open Core
open Util

module Operation = struct
  type t =
    | Plus of int
    | Times of int
    | Double
    | Square
  [@@deriving sexp]

  let apply t old =
    match t with
    | Plus x -> old + x
    | Times x -> old * x
    | Double -> old * 2
    | Square -> old * old
  ;;
end

module Reduce_worry = struct
  type t =
    | Divide3
    | Take_mod of int
end

module Monkey = struct
  type t =
    { num : int
    ; items : int Queue.t
    ; operation : Operation.t
    ; test_divisible_by : int
    ; if_true_monkey_num : int
    ; if_false_monkey_num : int
    ; mutable items_inspected : int
    }
  [@@deriving sexp]

  let parse str =
    let lines = Array.of_list (String.split_lines str) in
    let num = Scanf.sscanf lines.(0) "Monkey %d:" Fn.id in
    let items =
      String.drop_prefix lines.(1) (String.length "  Starting items: ")
      |> String.split ~on:','
      |> List.map ~f:String.strip
      |> List.map ~f:Int.of_string
      |> Queue.of_list
    in
    let operation =
      Scanf.sscanf lines.(2) "  Operation: new = old %s %s" (fun op operand ->
        match op, operand with
        | "+", "old" -> Operation.Double
        | "+", _ -> Operation.Plus (Int.of_string operand)
        | "*", "old" -> Operation.Square
        | "*", _ -> Operation.Times (Int.of_string operand)
        | _ -> assert false)
    in
    let test_divisible_by = Scanf.sscanf lines.(3) "  Test: divisible by %d" Fn.id in
    let if_true_monkey_num =
      Scanf.sscanf lines.(4) "    If true: throw to monkey %d" Fn.id
    in
    let if_false_monkey_num =
      Scanf.sscanf lines.(5) "    If false: throw to monkey %d" Fn.id
    in
    { num
    ; items
    ; operation
    ; test_divisible_by
    ; if_true_monkey_num
    ; if_false_monkey_num
    ; items_inspected = 0
    }
  ;;

  let has_items t = not (Queue.is_empty t.items)

  let inspect_next_item t ~reduce_worry =
    t.items_inspected <- t.items_inspected + 1;
    let worry_level = Queue.dequeue_exn t.items in
    let worry_level = Operation.apply t.operation worry_level in
    let worry_level =
      match reduce_worry with
      | Reduce_worry.Divide3 -> worry_level / 3
      | Take_mod n -> worry_level % n
    in
    let dest_monkey =
      if worry_level % t.test_divisible_by = 0
      then t.if_true_monkey_num
      else t.if_false_monkey_num
    in
    worry_level, dest_monkey
  ;;
end

let parse_input input =
  String.substr_replace_all input ~pattern:"\n\n" ~with_:"$"
  |> String.split ~on:'$'
  |> List.to_array
  |> Array.map ~f:(fun monkey_s -> Monkey.parse monkey_s)
;;

let solve input =
  let run_monkeys monkeys iters ~reduce_worry =
    List.iter (List.range 0 iters) ~f:(fun _ ->
      Array.iter monkeys ~f:(fun monkey ->
        while Monkey.has_items monkey do
          let worry_level, dest_monkey = Monkey.inspect_next_item monkey ~reduce_worry in
          Queue.enqueue monkeys.(dest_monkey).items worry_level
        done));
    let items_inspected = Array.map monkeys ~f:(fun m -> m.items_inspected) in
    Array.sort items_inspected ~compare:Int.descending;
    List.take (Array.to_list items_inspected) 2 |> list_product
  in
  (* Part 1 *)
  let monkeys = parse_input input in
  let monkey_business = run_monkeys monkeys 20 ~reduce_worry:Reduce_worry.Divide3 in
  print_part1 monkey_business;
  (* Part 2 *)
  let monkeys = parse_input input in
  let reduce_worry =
    Reduce_worry.Take_mod
      (array_product (Array.map monkeys ~f:(fun m -> m.test_divisible_by)))
  in
  let monkey_business = run_monkeys monkeys 10000 ~reduce_worry in
  print_part1 monkey_business
;;
