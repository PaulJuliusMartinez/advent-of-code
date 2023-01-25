open Core
open Util

let from_snafu str =
  String.to_list str
  |> List.rev
  |> List.mapi ~f:(fun i ch ->
       let power_of_5 = Int.of_float (5. ** Int.to_float i) in
       power_of_5
       *
       match ch with
       | '2' -> 2
       | '1' -> 1
       | '0' -> 0
       | '-' -> -1
       | '=' -> -2
       | _ -> failwith "unknown snafu char")
  |> list_sum
;;

let to_snafu n =
  let sum = ref 0 in
  let power = ref 0. in
  while !sum < n do
    sum := !sum + (2 * Int.of_float (5. ** !power));
    power := !power +. 1.
  done;
  let chs = ref [] in
  let remaining = ref (!sum + n) in
  for pow = Int.of_float !power - 1 downto 0 do
    let to_power = Int.of_float (5. ** Float.of_int pow) in
    let ch =
      match !remaining / to_power with
      | 4 -> '2'
      | 3 -> '1'
      | 2 -> '0'
      | 1 -> '-'
      | 0 -> '='
      | _ -> failwith "bad"
    in
    remaining := !remaining % to_power;
    chs := ch :: !chs
  done;
  String.of_char_list (List.rev !chs)
;;

let solve input =
  let sum = String.split_lines input |> List.map ~f:from_snafu |> list_sum in
  print_part1_s (to_snafu sum)
;;
