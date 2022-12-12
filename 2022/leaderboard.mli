open Core
open Async

type t = Xtech | Affinity | Google | Otto | Jane_street

module Leaderboard_id : sig
  include String_id.S
end

val lookup : string -> t option
val to_leaderboard_id : t -> Leaderboard_id.t
val print : t -> year:int -> unit Deferred.t
