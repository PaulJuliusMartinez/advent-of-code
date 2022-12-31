open Core
open Async
open Cohttp
open Cohttp_async

type t =
  | Xtech
  | Affinity
  | Google
  | Otto
  | Jane_street

module Leaderboard_id =
  String_id.Make
    (struct
      let module_name = "Leaderboard_id"
    end)
    ()

let to_leaderboard_id = function
  | Xtech -> Leaderboard_id.of_string "378851"
  | Affinity -> Leaderboard_id.of_string "632609"
  | Google -> Leaderboard_id.of_string "411675"
  | Otto -> Leaderboard_id.of_string "989140"
  | Jane_street -> Leaderboard_id.of_string "2299815"
;;

let lookup name =
  let leaderboards =
    [ "js", Jane_street
    ; "jane-street", Jane_street
    ; "jane_street", Jane_street
    ; "janestreet", Jane_street
    ; "xtech", Xtech
    ; "affinity", Affinity
    ; "google", Google
    ; "otto", Otto
    ]
  in
  List.Assoc.find leaderboards ~equal:String.equal name
;;

let fetch_path t ~year =
  String.concat
    [ "https://adventofcode.com/"
    ; Int.to_string year
    ; "/leaderboard/private/view/"
    ; Leaderboard_id.to_string (to_leaderboard_id t)
    ; ".json"
    ]
;;

let ts_to_time_ns seconds = Time_ns.of_span_since_epoch (Time_ns.Span.of_int_sec seconds)

let cache_path t ~year =
  String.concat
    [ "leaderboard."
    ; Leaderboard_id.to_string (to_leaderboard_id t)
    ; "."
    ; Int.to_string year
    ; ".json"
    ]
;;

let last_fetched_at_key = "last_fetched_at"

let cache_data ~data ~cache_path =
  let fetch_time =
    Time_ns.now () |> Time_ns.to_span_since_epoch |> Time_ns.Span.to_int_sec
  in
  let data_with_last_fetched_key =
    let as_assoc = Yojson.Basic.Util.to_assoc data in
    `Assoc ((last_fetched_at_key, `Int fetch_time) :: as_assoc)
  in
  Yojson.Basic.to_file cache_path data_with_last_fetched_key
;;

let fetch_data t ~year =
  let cookie = String.strip (In_channel.read_all "cookie") in
  let headers = Header.of_list [ "cache-control", "max-age=0"; "cookie", cookie ] in
  let url = Uri.of_string (fetch_path t ~year) in
  let%bind _, body = Client.get ~headers url in
  Body.to_string body
;;

let max_fetch_frequency = Time_ns.Span.of_sec 30.

let load_data t ~year =
  let cache_path = cache_path t ~year in
  let refetch_data () =
    let%map fetched_data = fetch_data t ~year in
    let data = Yojson.Basic.from_string fetched_data in
    cache_data ~data ~cache_path;
    data
  in
  match%bind Sys.file_exists cache_path with
  | `Yes ->
    let json = Yojson.Basic.from_file cache_path in
    let open Yojson.Basic.Util in
    let last_fetched_at = json |> member last_fetched_at_key |> to_int |> ts_to_time_ns in
    let refetch_at = Time_ns.add last_fetched_at max_fetch_frequency in
    if Time_ns.( < ) (Time_ns.now ()) refetch_at then return json else refetch_data ()
  | _ -> refetch_data ()
;;

let print t ~year =
  let%map json = load_data t ~year in
  print_endline (Yojson.Basic.to_string json)
;;
