open Core
open Util

module Monkey = struct
  type t =
    | Human
    | Num of int
    | Plus of string * string
    | Minus of string * string
    | Times of string * string
    | Divide of string * string
    | Eq of string * string
  [@@deriving sexp, compare, hash]

  let parse input =
    String.split_lines input
    |> List.map ~f:(fun s ->
         let name, rest = Option.value_exn (String.lsplit2 s ~on:' ') in
         let name = String.prefix name 4 in
         let monkey =
           try Num (Int.of_string rest) with
           | _ ->
             Scanf.sscanf rest "%s %s %s" (fun l op r ->
               match op with
               | "+" -> Plus (l, r)
               | "-" -> Minus (l, r)
               | "*" -> Times (l, r)
               | "/" -> Divide (l, r)
               | _ -> failwith "invalid op")
         in
         name, monkey)
  ;;

  let to_eq = function
    | Human | Eq _ | Num _ -> failwith "Don't call to_eq on Num/Human/Eq monkey"
    | Plus (m1, m2) -> Eq (m1, m2)
    | Minus (m1, m2) -> Eq (m1, m2)
    | Times (m1, m2) -> Eq (m1, m2)
    | Divide (m1, m2) -> Eq (m1, m2)
  ;;

  let apply t m1v m2v =
    match t with
    | Human | Eq _ | Num _ -> failwith "Don't call apply on Num/Human/Eq monkey"
    | Plus _ -> m1v + m2v
    | Minus _ -> m1v - m2v
    | Times _ -> m1v * m2v
    | Divide _ -> m1v / m2v
  ;;

  let eval t values =
    match t with
    | Human -> None
    | Eq _ -> None
    | Num v -> Some v
    | Plus (m1, m2) | Minus (m1, m2) | Times (m1, m2) | Divide (m1, m2) ->
      (match Hashtbl.find values m1, Hashtbl.find values m2 with
       | Some m1v, Some m2v -> Some (apply t m1v m2v)
       | _ -> None)
  ;;

  let operands = function
    | Human | Num _ -> failwith "Don't call oeprands on Num/Human monkey"
    | Eq (m1, m2) -> m1, m2
    | Plus (m1, m2) -> m1, m2
    | Minus (m1, m2) -> m1, m2
    | Times (m1, m2) -> m1, m2
    | Divide (m1, m2) -> m1, m2
  ;;

  let op = function
    | Human | Num _ -> failwith "Don't call to_eq on Num/Human monkey"
    | Eq _ -> `Eq
    | Plus _ -> `Plus
    | Minus _ -> `Minus
    | Times _ -> `Times
    | Divide _ -> `Divide
  ;;

  let solve_human t_map values =
    let rec solve t_name dest_value =
      let t = Hashtbl.find_exn t_map t_name in
      match t with
      | Human -> dest_value
      | Num _ -> failwith "Don't call solve on Num"
      | _ ->
        let m1, m2 = operands t in
        let op = op t in
        let m1v = Hashtbl.find values m1 in
        let m2v = Hashtbl.find values m2 in
        (match m1v, m2v, op with
         | None, None, _ -> failwith "Can't solve both sides"
         | Some _, Some _, _ -> failwith "Already have solved both sides"
         | Some a, None, `Eq -> solve m2 a
         | None, Some b, `Eq -> solve m1 b
         | Some a, None, `Plus -> solve m2 (dest_value - a)
         | None, Some b, `Plus -> solve m1 (dest_value - b)
         | Some a, None, `Minus -> solve m2 (a - dest_value)
         | None, Some b, `Minus -> solve m1 (b + dest_value)
         | Some a, None, `Times -> solve m2 (dest_value / a)
         | None, Some b, `Times -> solve m1 (dest_value / b)
         | Some a, None, `Divide -> solve m2 (a / dest_value)
         | None, Some b, `Divide -> solve m1 (b * dest_value))
    in
    solve "root" 0
  ;;
end

let solve input =
  let names_and_monkeys = Monkey.parse input in
  let name_to_monkeys = Hashtbl.of_alist_exn (module String) names_and_monkeys in
  let monkey_values = Hashtbl.create (module String) in
  while Hashtbl.length monkey_values < Hashtbl.length name_to_monkeys do
    List.iter names_and_monkeys ~f:(fun (name, monkey) ->
      if not (Hashtbl.mem monkey_values name)
      then (
        match Monkey.eval monkey monkey_values with
        | None -> ()
        | Some v -> Hashtbl.add_exn monkey_values ~key:name ~data:v))
  done;
  print_part2 (Hashtbl.find_exn monkey_values "root");
  (* Part 2 *)
  let name_to_monkeys = Hashtbl.of_alist_exn (module String) names_and_monkeys in
  Hashtbl.set name_to_monkeys ~key:"humn" ~data:Monkey.Human;
  Hashtbl.set
    name_to_monkeys
    ~key:"root"
    ~data:(Monkey.to_eq (Hashtbl.find_exn name_to_monkeys "root"));
  let monkey_values = Hashtbl.create (module String) in
  let last_size = ref (-1) in
  while Hashtbl.length monkey_values <> !last_size do
    last_size := Hashtbl.length monkey_values;
    Hashtbl.iteri name_to_monkeys ~f:(fun ~key:name ~data:monkey ->
      if not (Hashtbl.mem monkey_values name)
      then (
        match Monkey.eval monkey monkey_values with
        | None -> ()
        | Some v -> Hashtbl.add_exn monkey_values ~key:name ~data:v))
  done;
  print_part2 (Monkey.solve_human name_to_monkeys monkey_values)
;;
