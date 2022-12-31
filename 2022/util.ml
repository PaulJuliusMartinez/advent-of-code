open Core

let print_part1_s solution = print_endline ("Part 1: " ^ solution)
let print_part1 solution = print_part1_s (Int.to_string solution)
let print_part2_s solution = print_endline ("Part 2: " ^ solution)
let print_part2 solution = print_part2_s (Int.to_string solution)
let list_sum = List.sum (module Int) ~f:Fn.id
let list_product = List.fold ~init:1 ~f:Int.( * )
let list_max l = Option.value_exn (List.max_elt ~compare:Int.compare l)
let list_min l = Option.value_exn (List.min_elt ~compare:Int.compare l)
let array_sum = Array.sum (module Int) ~f:Fn.id
let array_product = Array.fold ~init:1 ~f:Int.( * )
let array_max l = Option.value_exn (Array.max_elt ~compare:Int.compare l)
let array_min l = Option.value_exn (Array.min_elt ~compare:Int.compare l)

module Grid = struct
  type 'a t = 'a array array

  let width t = Array.length t.(0)
  let height t = Array.length t
  let in_range t ~x ~y = 0 <= x && x < width t && 0 <= y && y < height t
  let create = Array.make_matrix
  let map t ~f = Array.map t ~f:(fun row -> Array.map row ~f)
  let mapc t ~f = Array.mapi t ~f:(fun y row -> Array.mapi row ~f:(fun x e -> f ~x ~y e))

  let of_puzzle_input input ~f =
    let lines = String.split_lines input in
    let width = String.length (List.hd_exn lines) in
    let height = List.length lines in
    let chars = create ~dimx:width ~dimy:height '\x00' in
    List.iteri lines ~f:(fun y line ->
      List.iteri (String.to_list line) ~f:(fun x ch -> chars.(x).(y) <- ch));
    map chars ~f
  ;;

  let of_same_size grid default = create ~dimx:(width grid) ~dimy:(height grid) default
  let iter t ~f = Array.iter t ~f:(fun row -> Array.iter row ~f)
  let transpose t = Array.transpose t |> Option.value_exn

  let iterc t ~f =
    Array.iteri t ~f:(fun y row -> Array.iteri row ~f:(fun x e -> f ~x ~y e))
  ;;

  let max_elt t ~compare =
    Array.map t ~f:(fun row -> Option.value_exn (Array.max_elt row ~compare))
    |> Array.max_elt ~compare
    |> Option.value_exn
  ;;

  let min_elt t ~compare =
    Array.map t ~f:(fun row -> Option.value_exn (Array.max_elt row ~compare))
    |> Array.max_elt ~compare
    |> Option.value_exn
  ;;

  let max_of t ~f ~compare = map t ~f |> max_elt ~compare
  let min_of t ~f ~compare = map t ~f |> min_elt ~compare
  let max_of_int t ~f = max_of t ~f ~compare:Int.compare
  let min_of_int t ~f = min_of t ~f ~compare:Int.compare
  let maxc_of t ~f ~compare = mapc t ~f |> max_elt ~compare
  let minc_of t ~f ~compare = mapc t ~f |> min_elt ~compare
  let maxc_of_int t ~f = maxc_of t ~f ~compare:Int.compare
  let minc_of_int t ~f = maxc_of t ~f ~compare:Int.compare
  let count t ~f = Array.map t ~f:(fun row -> Array.count row ~f) |> array_sum

  let countc t ~f =
    Array.mapi t ~f:(fun y row -> Array.counti row ~f:(fun x e -> f ~x ~y e)) |> array_sum
  ;;

  module Int = struct
    let sum (t : int t) =
      Array.map t ~f:(fun row -> Array.sum (module Int) row ~f:Fn.id) |> array_sum
    ;;

    let max_elt = max_elt ~compare:Int.compare
    let min_elt = min_elt ~compare:Int.compare
  end
end
