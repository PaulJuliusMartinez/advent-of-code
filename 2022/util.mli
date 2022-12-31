val print_part1_s : string -> unit
val print_part1 : int -> unit
val print_part2_s : string -> unit
val print_part2 : int -> unit

(* Simple helpers for common operations on integer lists *)
val list_sum : int list -> int
val list_product : int list -> int
val list_max : int list -> int
val list_min : int list -> int
val array_sum : int array -> int
val array_product : int array -> int
val array_max : int array -> int
val array_min : int array -> int

module Grid : sig
  type 'a t = 'a array array

  val create : dimx:int -> dimy:int -> 'a -> 'a t
  val of_puzzle_input : string -> f:(char -> 'a) -> 'a t
  val of_same_size : 'a t -> 'b -> 'b t
  val width : 'a t -> int
  val height : 'a t -> int
  val in_range : 'a t -> x:int -> y:int -> bool
  val transpose : 'a t -> 'a t
  val map : 'a t -> f:('a -> 'b) -> 'b t
  val mapc : 'a t -> f:(x:int -> y:int -> 'a -> 'b) -> 'b t
  val iter : 'a t -> f:('a -> unit) -> unit
  val iterc : 'a t -> f:(x:int -> y:int -> 'a -> unit) -> unit
  val max_elt : 'a t -> compare:('a -> 'a -> int) -> 'a
  val min_elt : 'a t -> compare:('a -> 'a -> int) -> 'a
  val max_of : 'a t -> f:('a -> 'f) -> compare:('f -> 'f -> int) -> 'f
  val min_of : 'a t -> f:('a -> 'f) -> compare:('f -> 'f -> int) -> 'f
  val max_of_int : 'a t -> f:('a -> int) -> int
  val min_of_int : 'a t -> f:('a -> int) -> int
  val maxc_of : 'a t -> f:(x:int -> y:int -> 'a -> 'f) -> compare:('f -> 'f -> int) -> 'f
  val minc_of : 'a t -> f:(x:int -> y:int -> 'a -> 'f) -> compare:('f -> 'f -> int) -> 'f
  val maxc_of_int : 'a t -> f:(x:int -> y:int -> 'a -> int) -> int
  val minc_of_int : 'a t -> f:(x:int -> y:int -> 'a -> int) -> int
  val count : 'a t -> f:('a -> bool) -> int
  val countc : 'a t -> f:(x:int -> y:int -> 'a -> bool) -> int

  module Int : sig
    val sum : int t -> int
    val max_elt : int t -> int
    val min_elt : int t -> int
  end
end
