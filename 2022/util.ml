open Core

let print_part1_s solution = print_endline ("Part 1: " ^ solution)
let print_part1 solution = print_part1_s (Int.to_string solution)
let print_part2_s solution = print_endline ("Part 2: " ^ solution)
let print_part2 solution = print_part2_s (Int.to_string solution)
let list_sum = List.sum (module Int) ~f:Fn.id
let list_max l = Option.value_exn (List.max_elt ~compare:Int.compare l)
let list_min l = Option.value_exn (List.min_elt ~compare:Int.compare l)
