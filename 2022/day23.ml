open Core
open Util

module Pt = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash, fields]

  let create x y = { x; y }
end

let parse input =
  let elves = Hash_set.create (module Pt) in
  String.split_lines input
  |> List.iteri ~f:(fun y line ->
       String.to_list line
       |> List.iteri ~f:(fun x ch ->
            if Char.equal ch '#' then Hash_set.add elves (Pt.create x y)));
  elves
;;

let n = 0, -1
let ne = 1, -1
let e = 1, 0
let se = 1, 1
let s = 0, 1
let sw = -1, 1
let w = -1, 0
let nw = -1, -1
let all_dirs = [ n; ne; e; se; s; sw; w; nw ]
let norths = [ n; nw; ne ]
let souths = [ s; se; sw ]
let wests = [ w; sw; nw ]
let easts = [ e; ne; se ]
let dir_checks = [ norths; souths; wests; easts ]

let incr_count counts pt =
  Hashtbl.change counts pt ~f:(function
    | None -> Some 1
    | Some c -> Some (c + 1))
;;

let propose_move elf elves dir_checks =
  let { Pt.x; y } = elf in
  let all_empty deltas =
    List.for_all deltas ~f:(fun (dx, dy) ->
      not (Hash_set.mem elves (Pt.create (x + dx) (y + dy))))
  in
  let all_surrounding_empty = all_empty all_dirs in
  if all_surrounding_empty
  then None
  else
    List.find dir_checks ~f:all_empty
    |> Option.map ~f:List.hd_exn
    |> Option.map ~f:(fun (dx, dy) -> Pt.create (x + dx) (y + dy))
;;

let run_round elves dir_checks =
  let proposals = Hashtbl.create (module Pt) in
  let proposal_counts = Hashtbl.create (module Pt) in
  let any_moved = ref false in
  Hash_set.iter elves ~f:(fun elf ->
    match propose_move elf elves dir_checks with
    | None -> ()
    | Some proposal ->
      Hashtbl.add_exn proposals ~key:elf ~data:proposal;
      incr_count proposal_counts proposal);
  let new_elves =
    List.map (Hash_set.to_list elves) ~f:(fun elf ->
      match Hashtbl.find proposals elf with
      | None -> elf
      | Some proposal ->
        if Hashtbl.find_exn proposal_counts proposal = 1
        then (
          any_moved := true;
          proposal)
        else elf)
    |> Hash_set.of_list (module Pt)
  in
  new_elves, !any_moved
;;

let solve input =
  let orig_dir_checks = dir_checks in
  let elves = ref (parse input) in
  let dir_checks = ref orig_dir_checks in
  for _ = 1 to 10 do
    (* printf "There are %d elves\n" (Hash_set.length !elves); *)
    elves := fst (run_round !elves !dir_checks);
    let hd = List.hd_exn !dir_checks in
    dir_checks := List.concat [ List.tl_exn !dir_checks; [ hd ] ]
  done;
  let pts = Hash_set.to_list !elves in
  let xs = List.map pts ~f:Pt.x in
  let ys = List.map pts ~f:Pt.y in
  let x_width = list_max xs - list_min xs + 1 in
  let y_height = list_max ys - list_min ys + 1 in
  print_part1 ((x_width * y_height) - Hash_set.length !elves);
  let elves = ref (parse input) in
  let dir_checks = ref orig_dir_checks in
  let round_count = ref 0 in
  let any_moved = ref true in
  while !any_moved do
    let new_elves, moved = run_round !elves !dir_checks in
    elves := new_elves;
    let hd = List.hd_exn !dir_checks in
    dir_checks := List.concat [ List.tl_exn !dir_checks; [ hd ] ];
    incr round_count;
    any_moved := moved
  done;
  print_part2 !round_count
;;
