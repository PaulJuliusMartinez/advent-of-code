open Core
open Util

module Point = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash]

  let create x y = { x; y }
end

let height = function
  | 'S' -> Char.to_int 'a'
  | 'E' -> Char.to_int 'z'
  | ch -> Char.to_int ch
;;

let solve input =
  let grid = Grid.of_puzzle_input input ~f:Fn.id in
  let max_cost = Grid.width grid * Grid.height grid * 100 in
  let sx, sy, _ = Grid.findc_exn grid ~f:(fun ~x:_ ~y:_ ch -> Char.equal ch 'S') in
  let ex, ey, _ = Grid.findc_exn grid ~f:(fun ~x:_ ~y:_ ch -> Char.equal ch 'E') in
  let shortest_paths = Hashtbl.create (module Point) in
  Hashtbl.add_exn shortest_paths ~key:(Point.create ex ey) ~data:0;
  let frontier =
    Pairing_heap.create
      ~cmp:(fun pt1 pt2 ->
        Int.compare
          (Hashtbl.find_exn shortest_paths pt1)
          (Hashtbl.find_exn shortest_paths pt2))
      ()
  in
  Pairing_heap.add frontier (Point.create ex ey);
  while not (Pairing_heap.is_empty frontier) do
    let curr = Pairing_heap.pop_exn frontier in
    let { Point.x; y } = curr in
    let cost_to_curr = Hashtbl.find_exn shortest_paths curr in
    let cost_to_neighbor = cost_to_curr + 1 in
    let curr_height = height grid.(x).(y) in
    Grid.iterc_neighbors grid ~x ~y ~f:(fun ~nx ~ny neighbor_ch ->
      let neighbor = Point.create nx ny in
      if Grid.in_range grid ~x:nx ~y:ny && height neighbor_ch >= curr_height - 1
      then
        if cost_to_neighbor
           < Option.value (Hashtbl.find shortest_paths neighbor) ~default:max_cost
        then (
          ignore (Hashtbl.add shortest_paths ~key:neighbor ~data:(cost_to_curr + 1));
          Pairing_heap.add frontier neighbor))
  done;
  print_part1 (Hashtbl.find_exn shortest_paths (Point.create sx sy));
  let start_height = height 'a' in
  let distance_to_end_from_a =
    Grid.mapc grid ~f:(fun ~x ~y ch ->
      if height ch = start_height
      then Option.value (Hashtbl.find shortest_paths (Point.create x y)) ~default:max_cost
      else max_cost)
  in
  print_part2 (Grid.Int.min_elt distance_to_end_from_a)
;;
