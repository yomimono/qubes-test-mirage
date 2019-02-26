(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

(** This should be run in your development VM as:
    qrexec-client-vm dom0 talex5.TestMirage dev.native mir-image.xen *)

open Lwt.Infix
let log = Utils.log

let to_dom0 = Lwt_io.stdout
let from_dom0 = Lwt_io.stdin
let to_human = Utils.fd_open_env ~mode:Lwt_io.output "SAVED_FD_1"
let from_human = Utils.fd_open_env ~mode:Lwt_io.input "SAVED_FD_0"

let upload vm_name () =
  (* Wait for "Ready". Connection sometimes seems to hang if we send first. *)
  Utils.expect "Ready" from_dom0 >>= fun () ->
  Lwt_io.write_line to_dom0 vm_name >>= fun () ->
  Utils.expect "Booting" from_dom0 >>= fun () ->
  Lwt.async (fun () -> Utils.copy from_human to_dom0);
  Utils.copy from_dom0 to_human

let report_error ex =
  let msg =
    match ex with
    | Failure msg -> msg
    | ex -> Printexc.to_string ex in
  output_string stderr (msg ^ "\n");
  flush stderr;
  exit 1

let () =
  match Sys.argv with
  | [| _; vm_name |] -> Lwt_main.run (Lwt.catch (upload vm_name) report_error)
  | _ -> failwith "Usage: test-mirage my-appvm"
