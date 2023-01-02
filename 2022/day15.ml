open Core
open Util

module Pt = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, compare, hash]

  let create x y = { x; y }
  let manhattan p1 p2 = Int.abs (p1.x - p2.x) + Int.abs (p1.y - p2.y)

  let points_exactly_n_manhattan_away pt n =
    let deltas =
      [ (-1, 0), (1, 1); (0, 1), (1, -1); (1, 0), (-1, -1); (0, -1), (-1, 1) ]
    in
    List.concat_map deltas ~f:(fun ((dx, dy), (sx, sy)) ->
      let vx = pt.x + (dx * n) in
      let vy = pt.y + (dy * n) in
      List.map (List.range 0 n) ~f:(fun s -> create (vx + (s * sx)) (vy + (s * sy))))
  ;;
end

let parse input =
  String.split_lines input
  |> List.map ~f:(fun s ->
       Scanf.sscanf
         s
         "Sensor at x=%d, y=%d: closest beacon is at x=%d, y=%d"
         (fun sx sy bx by -> Pt.create sx sy, Pt.create bx by))
;;

let solve input =
  let sensors_and_beacons = parse input in
  let sensors_and_ranges =
    List.map sensors_and_beacons ~f:(fun (s, b) -> s, Pt.manhattan s b)
  in
  let beacons = Hash_set.of_list (module Pt) (List.map sensors_and_beacons ~f:snd) in
  let max_range = list_max (List.map sensors_and_ranges ~f:(fun (_, r) -> r)) in
  let xs = List.map sensors_and_ranges ~f:(fun (s, _) -> s.x) in
  let min_x = list_min xs - max_range - 1 in
  let max_x = list_max xs + max_range + 1 in
  let x_poses = List.range ~start:`inclusive min_x ~stop:`inclusive max_x in
  let can_be_beacon_at pt =
    List.for_all sensors_and_ranges ~f:(fun (s, r) -> Pt.manhattan pt s > r)
  in
  let part1y = 2_000_000 in
  let num_positions_no_beacon =
    List.count x_poses ~f:(fun x -> not (can_be_beacon_at (Pt.create x part1y)))
  in
  let beacons_at_part1y = Hash_set.count beacons ~f:(fun b -> b.y = part1y) in
  print_part1 (num_positions_no_beacon - beacons_at_part1y);
  let part2 = ref None in
  List.iter sensors_and_ranges ~f:(fun (b, r) ->
    if Option.is_none !part2
    then (
      let border_points = Pt.points_exactly_n_manhattan_away b (r + 1) in
      List.iter border_points ~f:(fun bp ->
        if 0 <= bp.x && bp.x < 4_000_000 && 0 <= bp.y && bp.y < 4_000_000
        then
          if can_be_beacon_at bp
          then (
            let tuning_frequency = (bp.x * 4_000_000) + bp.y in
            part2 := Some tuning_frequency))));
  print_part2 (Option.value_exn !part2)
;;
