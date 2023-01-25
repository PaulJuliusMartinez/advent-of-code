open Core
open Util

module Pt = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash, fields]

  let create x y = { x; y }
  let neighbors_and_same_deltas = [ 1, 0; 0, 1; -1, 0; 0, -1; 0, 0 ]

  let neighbors_and_same t =
    List.map neighbors_and_same_deltas ~f:(fun (dx, dy) -> create (t.x + dx) (t.y + dy))
  ;;
end

module Blizzard = struct
  type t =
    { offset : int
    ; delta : int
    ; size : int
    }
  [@@deriving sexp, compare, hash]

  let create ~offset ~delta ~size = { offset; delta; size }
  let at_pos_at_time t ~pos ~time = (t.offset + (t.delta * time)) % t.size = pos
end

module Valley = struct
  type t =
    { width : int
    ; height : int
    ; by_col : (int, Blizzard.t list) Hashtbl.t
    ; by_row : (int, Blizzard.t list) Hashtbl.t
    }

  let parse input =
    let by_col = Hashtbl.create (module Int) in
    let by_row = Hashtbl.create (module Int) in
    let add_blizzard by_z z blizzard =
      Hashtbl.change by_z z ~f:(function
        | None -> Some [ blizzard ]
        | Some blizzards -> Some (blizzard :: blizzards))
    in
    let lines = String.split_lines input in
    let height = List.length lines - 2 in
    let width = String.length (List.hd_exn lines) - 2 in
    let lines = List.take (List.drop lines 1) height in
    List.iteri lines ~f:(fun row line ->
      let chars = List.take (List.drop (String.to_list line) 1) width in
      List.iteri chars ~f:(fun col ch ->
        match ch with
        | '>' ->
          add_blizzard by_row row (Blizzard.create ~offset:col ~delta:1 ~size:width)
        | '<' ->
          add_blizzard by_row row (Blizzard.create ~offset:col ~delta:(-1) ~size:width)
        | '^' ->
          add_blizzard by_col col (Blizzard.create ~offset:row ~delta:(-1) ~size:height)
        | 'v' ->
          add_blizzard by_col col (Blizzard.create ~offset:row ~delta:1 ~size:height)
        | _ -> ()));
    { width; height; by_col; by_row }
  ;;

  let is_start _t pt =
    let { Pt.x; y } = pt in
    x = 0 && y = -1
  ;;

  let is_end t pt =
    let { Pt.x; y } = pt in
    x = t.width - 1 && y = t.height
  ;;

  let end_ t = Pt.create (t.width - 1) t.height

  let open_at_time t pt time =
    if is_start t pt || is_end t pt
    then true
    else (
      let { Pt.x; y } = pt in
      let horizontals = Hashtbl.find_or_add t.by_col x ~default:(fun () -> []) in
      let verticals = Hashtbl.find_or_add t.by_row y ~default:(fun () -> []) in
      List.for_all horizontals ~f:(fun b -> not (Blizzard.at_pos_at_time b ~pos:y ~time))
      && List.for_all verticals ~f:(fun b -> not (Blizzard.at_pos_at_time b ~pos:x ~time)))
  ;;

  let in_bounds t pt =
    if is_start t pt || is_end t pt
    then true
    else (
      let { Pt.x; y } = pt in
      0 <= x && x < t.width && 0 <= y && y < t.height)
  ;;
end

module State = struct
  type t =
    { pos : Pt.t
    ; time : int
    }
  [@@deriving sexp, compare, hash, fields]

  let create pos time = { pos; time }
end

let solve input =
  let valley = Valley.parse input in
  let start = Pt.create 0 (-1) in
  let end_ = Valley.end_ valley in
  let time_to ~start ~end_ start_time =
    let states = Hash_set.create (module State) in
    let queue = Queue.of_list [ State.create start start_time ] in
    let arrival_time = ref None in
    while Option.is_none !arrival_time do
      let { State.pos; time } = Queue.dequeue_exn queue in
      if Pt.compare pos end_ = 0
      then arrival_time := Some time
      else
        List.iter (Pt.neighbors_and_same pos) ~f:(fun next_pos ->
          if Valley.in_bounds valley next_pos
             && Valley.open_at_time valley next_pos (time + 1)
          then (
            let next_state = State.create next_pos (time + 1) in
            if not (Hash_set.mem states next_state)
            then (
              Hash_set.add states next_state;
              Queue.enqueue queue next_state)))
    done;
    Option.value_exn !arrival_time
  in
  let time_to_end = time_to ~start ~end_ 0 in
  print_part1 time_to_end;
  let time_back_to_start = time_to ~start:end_ ~end_:start time_to_end in
  let time_back_to_end = time_to ~start ~end_ time_back_to_start in
  print_part2 time_back_to_end
;;
