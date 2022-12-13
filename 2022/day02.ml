open Core
open Util

let rock = 1
let paper = 2
let scissors = 3
let loss = 0
let draw = 3
let win = 6

let rps_result = function
  | "A X" -> rock + draw
  | "B X" -> rock + loss
  | "C X" -> rock + win
  | "A Y" -> paper + win
  | "B Y" -> paper + draw
  | "C Y" -> paper + loss
  | "A Z" -> scissors + loss
  | "B Z" -> scissors + win
  | "C Z" -> scissors + draw
  | _ -> 10000
;;

let rps_result2 = function
  | "A X" -> loss + scissors (* loses to rock *)
  | "B X" -> loss + rock (* loses to paper *)
  | "C X" -> loss + paper (* loses to scissors *)
  | "A Y" -> draw + rock (* draws with rock *)
  | "B Y" -> draw + paper (* draws with paper *)
  | "C Y" -> draw + scissors (* draws with scissors *)
  | "A Z" -> win + paper (* beats rock *)
  | "B Z" -> win + scissors (* beats paper *)
  | "C Z" -> win + rock (* beats scissors *)
  | _ -> 10000
;;

let solve input =
  let lines = String.split_lines input in
  let score = List.sum (module Int) ~f:rps_result lines in
  print_part1 score;
  let score2 = List.sum (module Int) ~f:rps_result2 lines in
  print_part2 score2
;;
