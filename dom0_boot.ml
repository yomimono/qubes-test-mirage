(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

(** This should be compiled and installed in dom0 as e.g. /usr/local/bin/test-mirage-dom0
    That path should also be placed in /etc/qubes-rpc/talex5.TestMirage
    and a policy allowing it added to /etc/qubes-rpc/policy/talex5.TestMirage *)

open Lwt.Infix
open Dom0

let main () =
  Lwt_io.write_line to_dev "Ready" >>= fun () ->
  Lwt_io.read_line from_dev >>= fun vm_name ->
  Lwt_io.write_line to_dev "Booting" >>= fun () ->
  Lwt_io.flush to_dev >>= fun () ->
  Unix.dup2 Unix.stdout Unix.stderr;
  let start_cmd = ("", [| "qvm-start"; vm_name |]) in
  let stop_cmd = ("", [| "qvm-kill"; vm_name |]) in
  Lwt_process.exec ~stdin:`Close ~stdout:`Keep ~stderr:(`FD_copy Unix.stdout) stop_cmd >>= fun _status ->
  Lwt_process.exec ~stdin:`Close ~stderr:(`FD_copy Unix.stdout) start_cmd >>= function
  | Unix.WEXITED 0 ->
      Printf.printf "Connecting to %s console...\n%!" vm_name;
      Unix.execv "/usr/bin/sudo" [| "/usr/bin/sudo"; "xl"; "console"; vm_name |]
  | _ ->
      let log_file = Printf.sprintf "/var/log/xen/console/guest-%s.log" vm_name in
      Printf.printf "qvm-start failed; showing tail of %s\n%!" log_file;
      Unix.execv "/usr/bin/tail" [| "/usr/bin/tail"; log_file |]

let () =
  Lwt_main.run (Lwt.catch main report_error)
