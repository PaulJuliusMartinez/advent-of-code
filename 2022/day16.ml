open Core
open Util

module Valve = struct
  type t =
    { name : string
    ; mutable flow : int
    ; mutable neighbors : t list
    }

  let name t = t.name
  let flow t = t.flow
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

module Volcano_escape = struct
  module Action = struct
    type t =
      | Moving_to of int * Valve.t
      | Opening of Valve.t

    let to_string = function
      | Moving_to (t, v) -> sprintf "Moving to %s; arrive in %d" (Valve.name v) t
      | Opening v -> sprintf "Opening %s" (Valve.name v)
    ;;

    let valve = function
      | Moving_to (_, v) -> v
      | Opening v -> v
    ;;

    let time = function
      | Moving_to (t, _) -> t
      | Opening _ -> 0
    ;;

    let decrement t mins =
      if mins = 0
      then t
      else (
        match t with
        | Moving_to (time, v) -> Moving_to (time - mins, v)
        | Opening _ -> t)
    ;;

    let _equal t1 t2 =
      match t1, t2 with
      | Moving_to (t1, v1), Moving_to (t2, v2) ->
        t1 = t2 && String.equal (Valve.name v1) (Valve.name v2)
      | Opening v1, Opening v2 -> String.equal (Valve.name v1) (Valve.name v2)
      | _ -> false
    ;;
  end

  type t =
    { curr_flow : int
    ; pressure_released : int
    ; minute : int
    ; valves_released : String.Set.t
    ; curr_action : Action.t
    ; ele_action : Action.t
    ; max_time : int
    }

  let init ~start ~max_time ~with_elephant =
    { curr_flow = 0
    ; pressure_released = 0
    ; minute = 1
    ; valves_released = String.Set.of_list [ Valve.name start ]
    ; curr_action = Action.Moving_to (0, start)
    ; ele_action = Action.Moving_to ((if with_elephant then 0 else max_time + 10), start)
    ; max_time
    }
  ;;

  let _print_state
    { curr_flow; pressure_released; minute; valves_released; curr_action; ele_action; _ }
    =
    printf "  pressure released: %d\n" pressure_released;
    printf "  current flow: %d\n" curr_flow;
    printf "  minute: %d\n" minute;
    printf
      "  valves visited: %s\n"
      (String.concat ~sep:", " (Set.to_list valves_released));
    printf "  curr action: %s\n" (Action.to_string curr_action);
    printf "  ele action: %s\n" (Action.to_string ele_action)
  ;;

  let next_states t valve_distances =
    let { curr_flow
        ; pressure_released
        ; minute
        ; valves_released
        ; curr_action
        ; ele_action
        ; max_time
        }
      =
      t
    in
    (* printf "-----------------------------------------\n"; *)
    (* printf "Current state:\n"; *)
    (* print_state t; *)
    if minute > max_time
    then []
    else (
      let flow_increase = ref 0 in
      let complete_action = function
        | Action.Opening v -> flow_increase := !flow_increase + Valve.flow v
        | _ -> ()
      in
      complete_action curr_action;
      complete_action ele_action;
      let curr_flow = curr_flow + !flow_increase in
      let pressure_released = pressure_released + curr_flow in
      let valves_released = ref valves_released in
      let next_actions action =
        let curr_valve = Action.valve action in
        let move_to_new_valve () =
          let best_distances = Hashtbl.find_exn valve_distances (Valve.name curr_valve) in
          List.filter_map best_distances ~f:(fun (distance, v) ->
            if String.equal (Valve.name v) (Valve.name curr_valve)
            then None
            else if Set.mem !valves_released (Valve.name v)
            then None
            else if minute + distance > max_time
            then None
            else Some (Action.Moving_to (distance - 1, v)))
        in
        let nexts =
          match action with
          | Action.Moving_to (0, v) ->
            if Set.mem !valves_released (Valve.name v)
            then move_to_new_valve ()
            else (
              valves_released := Set.add !valves_released (Valve.name v);
              [ Action.Opening v ])
          | Action.Moving_to (n, v) -> [ Action.Moving_to (n - 1, v) ]
          | Action.Opening _ -> move_to_new_valve ()
        in
        if List.is_empty nexts then [ Action.Moving_to (max_time, curr_valve) ] else nexts
      in
      let next_curr_actions = next_actions curr_action in
      let next_ele_actions = next_actions ele_action in
      let compute_next_state next_curr_action next_ele_action =
        let curr_valve = Valve.name (Action.valve next_curr_action) in
        let ele_valve = Valve.name (Action.valve next_ele_action) in
        if String.equal curr_valve ele_valve && not (String.equal curr_valve "AA")
        then None
        else (
          let time_skipped =
            list_min
              [ Action.time next_curr_action
              ; Action.time next_ele_action
              ; Int.max 0 (max_time - minute - 2)
              ]
          in
          let next_state =
            { curr_flow
            ; pressure_released = pressure_released + (curr_flow * time_skipped)
            ; minute = minute + 1 + time_skipped
            ; valves_released = !valves_released
            ; curr_action = Action.decrement next_curr_action time_skipped
            ; ele_action = Action.decrement next_ele_action time_skipped
            ; max_time
            }
          in
          (* printf "Next state (time skipped = %d):\n" time_skipped; *)
          (* print_state next_state; *)
          Some next_state)
      in
      if minute = 1
      then
        List.concat_mapi next_curr_actions ~f:(fun i next_curr_action ->
          List.filter_mapi next_ele_actions ~f:(fun j next_ele_action ->
            if j <= i then None else compute_next_state next_curr_action next_ele_action))
      else
        List.concat_map next_curr_actions ~f:(fun next_curr_action ->
          List.filter_map next_ele_actions ~f:(fun next_ele_action ->
            compute_next_state next_curr_action next_ele_action)))
  ;;
end

let solve input =
  let valves = Valve.parse input in
  let shortest_paths = Hashtbl.create (module String) in
  Hashtbl.iter valves ~f:(fun v ->
    ignore (Hashtbl.add shortest_paths ~key:v.name ~data:(Valve.shortest_paths valves v)));
  let interesting_valves =
    Hashtbl.to_alist valves |> List.map ~f:snd |> List.filter ~f:(fun v -> v.flow > 0)
  in
  let interesting_names =
    String.Set.of_list ("AA" :: List.map interesting_valves ~f:(fun v -> v.name))
  in
  List.iter interesting_valves ~f:(fun v -> printf "Valve %s has flow %d\n" v.name v.flow);
  let best_neighbors = Hashtbl.create (module String) in
  Set.iter interesting_names ~f:(fun v ->
    let v = Hashtbl.find_exn valves v in
    let paths_from_v = Hashtbl.find_exn shortest_paths v.name in
    let sorted_neighbors =
      List.map interesting_valves ~f:(fun v ->
        let cost_to_v = Hashtbl.find_exn paths_from_v v.name in
        let flow_from_v = v.flow in
        cost_to_v, flow_from_v, v)
      |> List.sort ~compare:(fun (c1, f1, _) (c2, f2, _) ->
           let res = Int.compare c1 c2 in
           if res <> 0 then res else Int.compare f2 f1)
      |> List.map ~f:(fun (c, _, v) -> c, v)
    in
    Hashtbl.add_exn best_neighbors ~key:v.name ~data:sorted_neighbors);
  Hashtbl.iteri best_neighbors ~f:(fun ~key:start ~data:neighbors ->
    printf "------\n";
    List.iter neighbors ~f:(fun (c, n) ->
      printf "From %s to %s takes %d (flow %d)\n" start n.name c n.flow));
  let solve ~with_elephant ~max_time =
    let most_pressure = ref 0 in
    let states = Queue.create () in
    let start = Hashtbl.find_exn valves "AA" in
    let initial_state = Volcano_escape.init ~start ~max_time ~with_elephant in
    Queue.enqueue states initial_state;
    while not (Queue.is_empty states) do
      let state = Queue.dequeue_exn states in
      if state.pressure_released > !most_pressure
      then (
        most_pressure := state.pressure_released;
        printf "Minute %d: pressure released = %d\n" state.minute !most_pressure;
        Out_channel.flush Out_channel.stdout);
      let next_states = Volcano_escape.next_states state best_neighbors in
      Queue.enqueue_all states next_states
    done;
    !most_pressure
  in
  print_part1 (solve ~with_elephant:false ~max_time:30);
  print_part2 (solve ~with_elephant:true ~max_time:26)
;;

(* Too low: 2035 *)
(* No: 2052 *)
(* No: 2064 *)
(* No: 2085 *)
(* No: 2174 *)
(* No: 2248 *)
(* No: 2264 *)
