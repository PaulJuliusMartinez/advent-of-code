open Core
open Util

let parse input = String.split_lines input |> List.map ~f:Int.of_string

module DLL = struct
  type t =
    { value : int
    ; mutable next : t option
    ; mutable prev : t option
    }

  let of_list nums =
    let nodes =
      List.map nums ~f:(fun n -> { value = n; next = None; prev = None }) |> Array.of_list
    in
    let len = Array.length nodes in
    for i = 0 to len - 2 do
      nodes.(i).next <- Some nodes.(i + 1);
      nodes.(i + 1).prev <- Some nodes.(i)
    done;
    nodes.(0).prev <- Some nodes.(len - 1);
    nodes.(len - 1).next <- Some nodes.(0);
    nodes
  ;;

  (* A <-> t <-> B <-> C *)
  (* A <-> B <-> t <-> C *)
  (* A.next
     B.prev/next
     t.prev/next
     C.prev *)
  let move_right t =
    let a = Option.value_exn t.prev in
    let b = Option.value_exn t.next in
    let c = Option.value_exn b.next in
    a.next <- Some b;
    b.prev <- Some a;
    b.next <- Some t;
    t.prev <- Some b;
    t.next <- Some c;
    c.prev <- Some t
  ;;

  (* A <-> B <-> t <-> C *)
  (* A <-> t <-> B <-> C *)
  (* A.next
     B.prev/next
     t.prev/next
     C.prev *)
  let move_left t =
    let b = Option.value_exn t.prev in
    let a = Option.value_exn b.prev in
    let c = Option.value_exn t.next in
    a.next <- Some t;
    t.prev <- Some a;
    t.next <- Some b;
    b.prev <- Some t;
    b.next <- Some c;
    c.prev <- Some b
  ;;

  let _to_list t =
    let l = ref [ t.value ] in
    let curr = ref (Option.value_exn t.next) in
    while !curr.value <> t.value do
      l := !curr.value :: !l;
      curr := Option.value_exn !curr.next
    done;
    List.rev !l
  ;;
end

module Mixer = struct
  type t =
    { num_nodes : int
    ; indexes_to_nodes : (int, DLL.t) Hashtbl.t
    ; index_of_0 : int
    }

  let create nums =
    let dll = DLL.of_list nums in
    let num_nodes = Array.length dll in
    let indexes_to_nodes = Hashtbl.create (module Int) in
    Array.iteri dll ~f:(fun i n -> Hashtbl.add_exn indexes_to_nodes ~key:i ~data:n);
    let index_of_0, _ = List.findi_exn nums ~f:(fun _ n -> n = 0) in
    { num_nodes; indexes_to_nodes; index_of_0 }
  ;;

  let mix t =
    for i = 0 to t.num_nodes - 1 do
      let node = Hashtbl.find_exn t.indexes_to_nodes i in
      let n = node.value in
      if n < 0
      then
        for _ = 1 to -n % (t.num_nodes - 1) do
          DLL.move_left node
        done
      else if n > 0
      then
        for _ = 1 to n % (t.num_nodes - 1) do
          DLL.move_right node
        done
    done
  ;;

  let sum_key_coords t =
    let coord0 = ref 0 in
    let coord1 = ref 0 in
    let coord2 = ref 0 in
    let curr = ref (Hashtbl.find_exn t.indexes_to_nodes t.index_of_0) in
    for i = 1 to 3000 do
      curr := Option.value_exn !curr.next;
      if i = 1000 then coord0 := !curr.value;
      if i = 2000 then coord1 := !curr.value;
      if i = 3000 then coord2 := !curr.value
    done;
    !coord0 + !coord1 + !coord2
  ;;
end

let solve input =
  let nums = parse input in
  let mixer = Mixer.create nums in
  Mixer.mix mixer;
  print_part1 (Mixer.sum_key_coords mixer);
  let decryption_key = 811589153 in
  let decrypted_nums = List.map nums ~f:(fun n -> n * decryption_key) in
  let mixer = Mixer.create decrypted_nums in
  for _ = 1 to 10 do
    Mixer.mix mixer
  done;
  print_part2 (Mixer.sum_key_coords mixer)
;;
