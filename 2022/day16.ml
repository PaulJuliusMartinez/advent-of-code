open Core
open Util

module Valve = struct
  type t =
    { name : string
    ; mutable flow : int
    ; mutable neighbors : t list
    }
  [@@deriving fields]

  let create name = { name; flow = 0; neighbors = [] }

  let parse input =
    let valves_by_name = Hashtbl.create (module String) in
    String.split_lines input
    |> List.iter ~f:(fun s ->
         let neighbors_s =
           snd
             (String.rsplit2_exn
                (String.substr_replace_all
                   (String.substr_replace_all s ~pattern:" to valves " ~with_:"$")
                   ~pattern:" to valve "
                   ~with_:"$")
                ~on:'$')
         in
         let neighbors =
           String.split
             (String.substr_replace_all neighbors_s ~pattern:", " ~with_:",")
             ~on:','
         in
         let neighbor_valves =
           List.map neighbors ~f:(fun name ->
             Hashtbl.find_or_add valves_by_name name ~default:(fun () -> create name))
         in
         let name, flow = Scanf.sscanf s "Valve %s has flow rate=%d" (fun n f -> n, f) in
         let valve =
           Hashtbl.find_or_add valves_by_name name ~default:(fun () -> create name)
         in
         valve.flow <- flow;
         valve.neighbors <- neighbor_valves);
    valves_by_name
  ;;

  let shortest_paths valves start =
    let max_cost = Hashtbl.length valves in
    let shortest_paths = Hashtbl.create (module String) in
    Hashtbl.add_exn shortest_paths ~key:start.name ~data:0;
    let frontier =
      Pairing_heap.create
        ~cmp:(fun v1 v2 ->
          Int.compare
            (Hashtbl.find_exn shortest_paths v1.name)
            (Hashtbl.find_exn shortest_paths v2.name))
        ()
    in
    Pairing_heap.add frontier start;
    while not (Pairing_heap.is_empty frontier) do
      let curr = Pairing_heap.pop_exn frontier in
      let cost_to_curr = Hashtbl.find_exn shortest_paths curr.name in
      let cost_to_neighbor = cost_to_curr + 1 in
      List.iter curr.neighbors ~f:(fun n ->
        if cost_to_neighbor
           < Option.value (Hashtbl.find shortest_paths n.name) ~default:max_cost
        then (
          ignore (Hashtbl.add shortest_paths ~key:n.name ~data:(cost_to_curr + 1));
          Pairing_heap.add frontier n))
    done;
    shortest_paths
  ;;
end

module Cache = struct
  module Best_result = struct
    type t =
      { opened_last_at : int
      ; last_at : string
      ; total_released : int
      }

    let _to_string t =
      sprintf "opened %s at %d, %d released" t.last_at t.opened_last_at t.total_released
    ;;
  end

  type t =
    { time : int
    ; flows : (string, int) Hashtbl.t
    ; shortest_paths : (string, (string, int) Hashtbl.t) Hashtbl.t
    ; best_result_including_and_ending_at : (string, Best_result.t) Hashtbl.t
    }

  let create time flows shortest_paths =
    { time
    ; flows
    ; shortest_paths
    ; best_result_including_and_ending_at = Hashtbl.create (module String)
    }
  ;;

  let cache_key valves ending_at = String.concat ~sep:" " (ending_at :: "<-" :: valves)

  let all_but_one vals =
    List.mapi vals ~f:(fun i one ->
      let others =
        List.filter_mapi vals ~f:(fun j other -> if i = j then None else Some other)
      in
      others, one)
  ;;

  let time_to t start end_ =
    Hashtbl.find_exn (Hashtbl.find_exn t.shortest_paths start) end_
  ;;

  let best_result_starting_at t valve =
    let time_to_open = time_to t "AA" valve + 1 in
    let flow = Hashtbl.find_exn t.flows valve in
    { Best_result.opened_last_at = time_to_open
    ; last_at = valve
    ; total_released = (t.time - time_to_open) * flow
    }
  ;;

  let rec best_result_visiting t ~valves ~ending_at : Best_result.t =
    let key = cache_key valves ending_at in
    Hashtbl.find_or_add t.best_result_including_and_ending_at key ~default:(fun () ->
      match valves with
      | [] -> best_result_starting_at t ending_at
      | _ ->
        let best_result =
          ref { Best_result.opened_last_at = 0; last_at = "AA"; total_released = 0 }
        in
        let flow = Hashtbl.find_exn t.flows ending_at in
        List.iter (all_but_one valves) ~f:(fun (prev, last_valve) ->
          let progress_to_last =
            best_result_visiting t ~valves:prev ~ending_at:last_valve
          in
          let time_to_ending_at = time_to t progress_to_last.last_at ending_at in
          let next_opened_at = progress_to_last.opened_last_at + time_to_ending_at + 1 in
          if next_opened_at < t.time
          then (
            let total_released =
              progress_to_last.total_released + ((t.time - next_opened_at) * flow)
            in
            if total_released > !best_result.total_released
            then
              best_result
                := { Best_result.opened_last_at = next_opened_at
                   ; last_at = ending_at
                   ; total_released
                   })
          else if progress_to_last.total_released > !best_result.total_released
          then best_result := progress_to_last);
        !best_result)
  ;;

  (* all_but_one [1; 2; 3; 4]
     ->
       [ [1; 2; 3], 4
       ; [1; 2; 4], 3
       ; [1; 3; 4], 2
       ; [2; 3; 4], 1
       ]
       *)
  let most_pressure_released_for t valves =
    (* Could end at any valve; so we'll check ending at each valve and
       take max. *)
    List.map (all_but_one valves) ~f:(fun (others, ending_at) ->
      (best_result_visiting t ~valves:others ~ending_at).total_released)
    |> list_max
  ;;
end

let disjoint_sets vals =
  if List.is_empty vals
  then []
  else (
    let rec disjoint_sets rest s1 s2 =
      match rest with
      | [] -> [ s1, s2 ]
      | hd :: tl ->
        let in1 = disjoint_sets tl (hd :: s1) s2 in
        let in2 = disjoint_sets tl s1 (hd :: s2) in
        List.concat [ in1; in2 ]
    in
    disjoint_sets (List.tl_exn vals) [ List.hd_exn vals ] [])
;;

let solve input =
  print_endline "";
  let valves = Valve.parse input in
  let shortest_paths = Hashtbl.create (module String) in
  Hashtbl.iter valves ~f:(fun v ->
    Hashtbl.add_exn shortest_paths ~key:v.name ~data:(Valve.shortest_paths valves v));
  let interesting_valves =
    Hashtbl.to_alist valves
    |> List.map ~f:snd
    |> List.filter ~f:(fun v -> v.flow > 0)
    |> List.sort ~compare:(fun v1 v2 -> String.compare v1.name v2.name)
  in
  let flows = Hashtbl.create (module String) in
  List.iter interesting_valves ~f:(fun v ->
    Hashtbl.add_exn flows ~key:v.name ~data:v.flow);
  let cache = Cache.create 30 flows shortest_paths in
  let interesting_valves =
    List.map interesting_valves ~f:Valve.name |> List.sort ~compare:String.compare
  in
  print_part1 (Cache.most_pressure_released_for cache interesting_valves);
  let max_pressure = ref 0 in
  let cache = Cache.create 26 flows shortest_paths in
  let all_disjoint_sets = List.tl_exn (disjoint_sets interesting_valves) in
  List.iter all_disjoint_sets ~f:(fun (s1, s2) ->
    let p1 = Cache.most_pressure_released_for cache s1 in
    let p2 = Cache.most_pressure_released_for cache s2 in
    let total_pressure_released = p1 + p2 in
    if total_pressure_released > !max_pressure
    then max_pressure := total_pressure_released);
  print_part2 !max_pressure
;;
