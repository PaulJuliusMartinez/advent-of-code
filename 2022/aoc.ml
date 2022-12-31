open Core
open Async

let solve =
  Command.async
    ~summary:"Solve a problem for a specific day"
    (let%map_open.Command day =
       flag "-day" (required int) ~doc:"day which day to solve"
     in
     fun () ->
       if day < 1 || 25 < day
       then
         return
           (ignore (failwith "Invalid day; must be in\nrange 1-25: " ^ Int.to_string day))
       else (
         let%map input = Problem_input.fetch_input ~year:2022 ~day in
         match day with
         | 1 -> Day01.solve input
         | 2 -> Day02.solve input
         | 3 -> Day03.solve input
         | 4 -> Day04.solve input
         | 5 -> Day05.solve input
         | 6 -> Day06.solve input
         | 7 -> Day07.solve input
         | 8 -> Day08.solve input
         | 9 -> Day09.solve input
         | _ -> failwith ("No solution implemented for Day " ^ Int.to_string day)))
;;

let print_leaderboard =
  Command.async
    ~summary:"Display a private Advent of Code leaderboard"
    (let%map_open.Command year =
       flag "-year" (required int) ~doc:"year (defaults to latest)"
     and leaderboard = anon (maybe_with_default "js" ("leaderboard" %: string)) in
     fun () ->
       match Leaderboard.lookup leaderboard with
       | None -> failwith ("Unknown leaderboard: " ^ leaderboard)
       | Some leaderboard -> Leaderboard.print leaderboard ~year)
;;

let command =
  Command.group
    ~summary:"Various commands related to Advent of Code"
    [ "solve", solve; "leaderboard", print_leaderboard ]
;;

let () = Command_unix.run command
