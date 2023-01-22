open Core
open Util

module Robot = struct
  type t =
    | Ore
    | Clay
    | Obsidian
    | Geode
  [@@deriving sexp, compare, equal, hash]

  let all = [ Ore; Clay; Obsidian; Geode ]
end

module Cost = struct
  type t =
    { ore : int
    ; clay : int
    ; obsidian : int
    }
  [@@deriving sexp, compare, hash, fields]

  let of_ore ore = { ore; clay = 0; obsidian = 0 }
  let of_ore_and_clay ore clay = { ore; clay; obsidian = 0 }
  let of_ore_and_obsidian ore obsidian = { ore; clay = 0; obsidian }
end

module Blueprint = struct
  type t =
    { id : int
    ; ore_robot_cost : Cost.t
    ; clay_robot_cost : Cost.t
    ; obsidian_robot_cost : Cost.t
    ; geode_robot_cost : Cost.t
    }
  [@@deriving sexp, compare, hash, fields]

  let parse input =
    String.split_lines input
    |> List.map ~f:(fun s ->
         Scanf.sscanf
           s
           "Blueprint %d: Each ore robot costs %d ore. Each clay robot costs %d ore. \
            Each obsidian robot costs %d ore and %d clay. Each geode robot costs %d ore \
            and %d obsidian."
           (fun id ore clay ob1 ob2 geo1 geo2 ->
           { id
           ; ore_robot_cost = Cost.of_ore ore
           ; clay_robot_cost = Cost.of_ore clay
           ; obsidian_robot_cost = Cost.of_ore_and_clay ob1 ob2
           ; geode_robot_cost = Cost.of_ore_and_obsidian geo1 geo2
           }))
  ;;

  let costs t =
    [ t.ore_robot_cost; t.clay_robot_cost; t.obsidian_robot_cost; t.geode_robot_cost ]
  ;;

  let non_ore_costs t = [ t.clay_robot_cost; t.obsidian_robot_cost; t.geode_robot_cost ]

  let cost_of t robot =
    match robot with
    | Robot.Ore -> t.ore_robot_cost
    | Clay -> t.clay_robot_cost
    | Obsidian -> t.obsidian_robot_cost
    | Geode -> t.geode_robot_cost
  ;;
end

module Robot_state = struct
  type t =
    { ore_robots : int
    ; clay_robots : int
    ; obsidian_robots : int
    ; geode_robots : int
    }
  [@@deriving sexp, compare, hash]
end

module Resources = struct
  type t = int * int * int * int [@@deriving sexp, compare, hash]

  let create ~ore ~clay ~obsidian ~geodes = ore, clay, obsidian, geodes

  let strictly_less (r1a, r1b, r1c, r1d) (r2a, r2b, r2c, r2d) =
    r1a <= r2a && r1b <= r2b && r1c <= r2c && r1d <= r2d
  ;;
end

module Factory = struct
  type t =
    { blueprint : Blueprint.t
    ; max_minutes : int
    ; mutable minute : int
    ; mutable ore : int
    ; mutable clay : int
    ; mutable obsidian : int
    ; mutable geodes : int
    ; mutable ore_robots : int
    ; mutable clay_robots : int
    ; mutable obsidian_robots : int
    ; mutable geode_robots : int
    ; max_ore_robots : int
    ; max_clay_robots : int
    ; max_obsidian_robots : int
    ; mutable waiting_to_build : Robot.t list
    ; mutable last_built : Robot.t option
    }
  [@@deriving sexp, compare]

  let create blueprint max_minutes =
    let costs = Blueprint.costs blueprint in
    { blueprint
    ; max_minutes
    ; minute = 0
    ; ore = 0
    ; clay = 0
    ; obsidian = 0
    ; geodes = 0
    ; ore_robots = 1
    ; clay_robots = 0
    ; obsidian_robots = 0
    ; geode_robots = 0
    ; max_ore_robots = list_max (List.map (Blueprint.non_ore_costs blueprint) ~f:Cost.ore)
    ; max_clay_robots = list_max (List.map costs ~f:Cost.clay)
    ; max_obsidian_robots = list_max (List.map costs ~f:Cost.obsidian)
    ; waiting_to_build = [ Robot.Ore; Robot.Clay ]
    ; last_built = None
    }
  ;;

  let robot_state t =
    { Robot_state.ore_robots = t.ore_robots
    ; clay_robots = t.clay_robots
    ; obsidian_robots = t.obsidian_robots
    ; geode_robots = t.geode_robots
    }
  ;;

  let resources t =
    Resources.create ~ore:t.ore ~clay:t.clay ~obsidian:t.obsidian ~geodes:t.geodes
  ;;

  let copy t = { t with blueprint = t.blueprint }

  let have_built_less_than_max t robot =
    match robot with
    | Robot.Ore -> t.ore_robots < t.max_ore_robots
    | Clay -> t.clay_robots < t.max_clay_robots
    | Obsidian -> t.obsidian_robots < t.max_obsidian_robots
    | Geode -> true
  ;;

  let have_resources_to_build t robot =
    let cost = Blueprint.cost_of t.blueprint robot in
    t.ore >= Cost.ore cost && t.clay >= Cost.clay cost && t.obsidian >= Cost.obsidian cost
  ;;

  let have_robots_to_build_resources_for t robot =
    match robot with
    | Robot.Ore -> true
    | Clay -> true
    | Obsidian -> t.clay_robots > 0
    | Geode -> t.obsidian_robots > 0
  ;;

  let not_too_late_to_build t robot =
    match robot with
    | Robot.Ore -> true
    | Clay -> t.minute < t.max_minutes - 5
    (* Create Clay on x (18)
       Get Additional clay on x + 1 (21)
       Create Obsidian you couldn't on x + 2 (20)
       Get Additional Obsidian on x + 3 (21)
       Build Geode you couldn't on x + 4 (22)
       Get extra Geode on x + 5 (23) *)
    | Obsidian -> t.minute < t.max_minutes - 3
    (* Create Obsidian on x (20)
       Get Additional Obsidian on x + 1 (21)
       Build Geode you couldn't on x + 2 (22)
       Get extra Geode on x + 3 (23) *)
    | Geode -> t.minute < t.max_minutes - 1
  ;;

  let should_build t robot =
    have_built_less_than_max t robot
    && have_resources_to_build t robot
    && not_too_late_to_build t robot
  ;;

  (* This is an INCORRECT optimization:
    let can_build_geode = have_resources_to_build t Robot.Geode in
    let can_build_obsidian = have_resources_to_build t Robot.Obsidian in
    &&
    match robot with
    | Robot.Ore -> (not can_build_geode) && not can_build_obsidian
    | Clay -> (not can_build_geode) && not can_build_obsidian
    | Obsidian -> true
    | Geode -> true
    *)

  let incr_resources t =
    t.minute <- t.minute + 1;
    t.ore <- t.ore + t.ore_robots;
    t.clay <- t.clay + t.clay_robots;
    t.obsidian <- t.obsidian + t.obsidian_robots;
    t.geodes <- t.geodes + t.geode_robots
  ;;

  let decr_resources t cost =
    t.ore <- t.ore - Cost.ore cost;
    t.clay <- t.clay - Cost.clay cost;
    t.obsidian <- t.obsidian - Cost.obsidian cost
  ;;

  let advance t =
    let build_futures =
      List.filter_map Robot.all ~f:(fun robot ->
        if (not (should_build t robot))
           || not (List.mem t.waiting_to_build robot ~equal:Robot.equal)
        then None
        else (
          let cost = Blueprint.cost_of t.blueprint robot in
          let next = copy t in
          incr_resources next;
          decr_resources next cost;
          (match robot with
           | Robot.Ore -> next.ore_robots <- next.ore_robots + 1
           | Clay -> next.clay_robots <- next.clay_robots + 1
           | Obsidian -> next.obsidian_robots <- next.obsidian_robots + 1
           | Geode -> next.geode_robots <- next.geode_robots + 1);
          next.waiting_to_build
            <- List.filter Robot.all ~f:(fun robot ->
                 have_built_less_than_max next robot
                 && have_robots_to_build_resources_for next robot);
          next.last_built <- Some robot;
          Some next))
    in
    let waiting_to_build =
      List.filter t.waiting_to_build ~f:(fun robot ->
        have_built_less_than_max t robot
        && have_robots_to_build_resources_for t robot
        && not (have_resources_to_build t robot))
    in
    if (not (List.is_empty waiting_to_build)) || List.is_empty build_futures
    then (
      incr_resources t;
      t.waiting_to_build <- waiting_to_build;
      t.last_built <- None;
      t :: build_futures)
    else build_futures
  ;;

  let run_for_n_minutes t =
    let factories = ref [ t ] in
    for _m = 1 to t.max_minutes do
      factories := List.concat_map !factories ~f:advance;
      (* We can get end up with multiple factories that have the same
         number of robots, but one factory has strictly more of every
         resource than the other. In these cases, we shouldn't continue
         running the factory with fewer resources. This seems like a lot
         of work to do, but it doesn't drastically reduce the branching
         factor and the total number of factories at each minute. *)
      let lists_by_robot_states = Hashtbl.create (module Robot_state) in
      List.iter !factories ~f:(fun f ->
        Hashtbl.change lists_by_robot_states (robot_state f) ~f:(function
          | None -> Some [ f ]
          | Some l -> Some (f :: l)));
      let new_factories = ref [] in
      Hashtbl.iteri lists_by_robot_states ~f:(fun ~key:_ ~data:fs ->
        let sorted =
          List.map fs ~f:(fun f -> f, resources f)
          |> List.sort ~compare:(fun (_, r1) (_, r2) -> Resources.compare r2 r1)
        in
        let best_fs, _ =
          List.fold sorted ~init:([], []) ~f:(fun (best_states, best_resources) (f, r) ->
            if List.exists best_resources ~f:(fun br -> Resources.strictly_less r br)
            then best_states, best_resources
            else f :: best_states, r :: best_resources)
        in
        new_factories := best_fs :: !new_factories);
      factories := List.concat !new_factories
      (* printf "There are %d factories after %d minutes\n" (List.length
         !factories) m *)
    done;
    list_max (List.map !factories ~f:(fun f -> f.geodes))
  ;;
end

let solve input =
  let blueprints = Blueprint.parse input in
  let quality_levels =
    List.map blueprints ~f:(fun blueprint ->
      let factory = Factory.create blueprint 24 in
      let max_geodes = Factory.run_for_n_minutes factory in
      blueprint.id * max_geodes)
  in
  print_part1 (list_sum quality_levels);
  let num_geodes =
    List.map (List.take blueprints 3) ~f:(fun blueprint ->
      let factory = Factory.create blueprint 32 in
      let max_geodes = Factory.run_for_n_minutes factory in
      max_geodes)
  in
  print_part2 (list_product num_geodes)
;;

(*

- Nothing -> Build X
- Build X -> Nothing  is always better

-> Only do nothing if waiting to build something

-> Waiting_to_build
-> After build -> waiting_to_build becomes [<everything you should build>]
-> If do nothing -> waiting_to_build becomes [<things you couldn't build>]
-> Only build something if in <waiting_to_build>
-> Only do nothing if nothing to do, or something you can't build (but
will eventually be able to build)


If you're going to do nothing:
  - You can't do nothing (or no reason to)
  - Waiting to build something; if you could
*)
