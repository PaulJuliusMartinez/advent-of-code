open Core
open Async
open Cohttp
open Cohttp_async

let input_url ~year ~day =
  String.concat
    [ "https://adventofcode.com/"
    ; Int.to_string year
    ; "/day/"
    ; Int.to_string day
    ; "/input"
    ]
;;

let input_path ~day =
  String.concat [ "dec"; (if day < 10 then "0" else ""); Int.to_string day; ".input" ]
;;

let fetch_input ~year ~day =
  let input_path = input_path ~day in
  match%bind Sys.file_exists input_path with
  | `Yes -> return (In_channel.read_all input_path)
  | _ ->
    let cookie = String.strip (In_channel.read_all "cookie") in
    let headers = Header.of_list [ "cache-control", "max-age=0"; "cookie", cookie ] in
    let url = Uri.of_string (input_url ~year ~day) in
    let%bind _, body = Client.get ~headers url in
    let%bind input = Body.to_string body in
    Out_channel.write_all input_path ~data:input;
    return input
;;
