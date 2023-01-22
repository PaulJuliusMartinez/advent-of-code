open Core
open Util

module Pt3 = struct
  type t =
    { x : int
    ; y : int
    ; z : int
    }
  [@@deriving sexp, compare, hash]

  let create x y z = { x; y; z }
end

let parse input =
  String.split_lines input
  |> List.map ~f:(fun s ->
       Scanf.sscanf s "%d,%d,%d" (fun x y z -> Pt3.create (10 * x) (10 * y) (10 * z)))
;;

(*


------+------------+-----
      |0, 1        | 1, 1
      |            |
    0, .5          |
      |            |
      |0, 0        | 1, 0
------+------------+-----
      |     .5, 0  |
      |            |
      |            |
    0, -.5         |

*)

let solve input =
  let droplets = parse input in
  let faces = Hashtbl.create (module Pt3) in
  let incr_faces pt =
    match Hashtbl.find faces pt with
    | None -> Hashtbl.add_exn faces ~key:pt ~data:1
    | Some count -> ignore (Hashtbl.set faces ~key:pt ~data:(count + 1))
  in
  List.iter droplets ~f:(fun pt ->
    let { Pt3.x; y; z } = pt in
    incr_faces (Pt3.create (x - 5) y z);
    incr_faces (Pt3.create (x + 5) y z);
    incr_faces (Pt3.create x (y - 5) z);
    incr_faces (Pt3.create x (y + 5) z);
    incr_faces (Pt3.create x y (z - 5));
    incr_faces (Pt3.create x y (z + 5)));
  let exposed = Hashtbl.count faces ~f:(fun c -> c = 1) in
  print_part1 exposed;
  let all_coords = List.concat_map droplets ~f:(fun pt -> [ pt.x; pt.y; pt.z ]) in
  let min_pt = list_min all_coords - 10 in
  let max_pt = list_max all_coords + 10 in
  let droplets = Hash_set.of_list (module Pt3) droplets in
  let air = Hash_set.create (module Pt3) in
  let queue = Queue.of_list [ Pt3.create min_pt min_pt min_pt ] in
  let maybe_enqueue_neighbor (n : Pt3.t) =
    if min_pt <= n.x
       && n.x <= max_pt
       && min_pt <= n.y
       && n.y <= max_pt
       && min_pt <= n.z
       && n.z <= max_pt
       && not (Hash_set.mem droplets n)
    then
      if not (Hash_set.mem air n)
      then (
        Hash_set.add air n;
        Queue.enqueue queue n)
  in
  while not (Queue.is_empty queue) do
    let pt = Queue.dequeue_exn queue in
    Hash_set.add air pt;
    let { Pt3.x; y; z } = pt in
    maybe_enqueue_neighbor (Pt3.create (x - 10) y z);
    maybe_enqueue_neighbor (Pt3.create (x + 10) y z);
    maybe_enqueue_neighbor (Pt3.create x (y - 10) z);
    maybe_enqueue_neighbor (Pt3.create x (y + 10) z);
    maybe_enqueue_neighbor (Pt3.create x y (z - 10));
    maybe_enqueue_neighbor (Pt3.create x y (z + 10))
  done;
  let outside_faces = Hashtbl.create (module Pt3) in
  let incr_faces_if_by_air face air_pt =
    if Hash_set.mem air air_pt
    then (
      match Hashtbl.find faces face with
      | None -> Hashtbl.add_exn outside_faces ~key:face ~data:1
      | Some count -> ignore (Hashtbl.set outside_faces ~key:face ~data:(count + 1)))
  in
  Hash_set.iter droplets ~f:(fun pt ->
    let { Pt3.x; y; z } = pt in
    incr_faces_if_by_air (Pt3.create (x - 5) y z) (Pt3.create (x - 10) y z);
    incr_faces_if_by_air (Pt3.create (x + 5) y z) (Pt3.create (x + 10) y z);
    incr_faces_if_by_air (Pt3.create x (y - 5) z) (Pt3.create x (y - 10) z);
    incr_faces_if_by_air (Pt3.create x (y + 5) z) (Pt3.create x (y + 10) z);
    incr_faces_if_by_air (Pt3.create x y (z - 5)) (Pt3.create x y (z - 10));
    incr_faces_if_by_air (Pt3.create x y (z + 5)) (Pt3.create x y (z + 10)));
  let exposed = Hashtbl.length outside_faces in
  print_part2 exposed
;;
