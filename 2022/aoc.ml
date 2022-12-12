open Core
open Async

let print_leaderboard =
  Command.async ~summary:"Display a private Advent of Code leaderboard"
    (let%map_open.Command year = flag "-y" (required int) ~doc:"year (defaults to latest)"
     and leaderboard = anon (maybe_with_default "js" ("leaderboard" %: string)) in
     fun () ->
       match Leaderboard.lookup leaderboard with
       | None -> failwith ("Unknown leaderboard: " ^ leaderboard)
       | Some leaderboard -> Leaderboard.print leaderboard ~year)
;;

(*
let command =
  Command.group ~summary:"Various commands related to Advent of Code"
    [ ("leaderboard", print_leaderboard) ]
;;
*)

let () = Command_unix.run print_leaderboard
