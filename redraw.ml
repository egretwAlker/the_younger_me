open Js_of_ocaml;;

let rk = 0.4;;
let ship_size = (0.1/.rk, 0.138/.rk);;
(* let cc = 47055.7931251;; *)
let cc = 0.8;;
let dcc = 1./.(cc*.cc);;
(* let inc = cc/.1000000.;; *)
let inc = cc/.30.;;

type tranv = {
  k1 : float;
  k2 : float;
  k3 : float;
  k4 : float;
  b1 : float;
  b2 : float;
};;

type imgdata = {
  mutable x : float;
  mutable y : float;
  mutable w : float;
  mutable h : float;
};;

let printimg i =
  Printf.printf "img : %f %f %f %f\n" i.x i.y i.w i.h;;

let nimg0 _ = {x=0.;y=0.;w=0.;h=0.};;
let img0 = nimg0 ();;

let id = {k1=1.;k2=0.;k3=0.;k4=1.;b1=0.;b2=0.};;

let comb t2 t1 = {
  k1 = t2.k1 *. t1.k1 +. t2.k3 *. t1.k2;
  k2 = t2.k2 *. t1.k1 +. t2.k4 *. t1.k2;
  k3 = t2.k1 *. t1.k3 +. t2.k3 *. t1.k4;
  k4 = t2.k2 *. t1.k3 +. t2.k4 *. t1.k4;
  b1 = t2.k1 *. t1.b1 +. t2.k3 *. t1.b2 +. t2.b1;
  b2 = t2.k2 *. t1.b1 +. t2.k4 *. t1.b2 +. t2.b2;
};;

let print_tv t =
  Printf.printf "tv: %f %f %f %f %f %f\n" t.k1 t.k2 t.k3 t.k4 t.b1 t.b2;;

(* let pship : vector ref = ref (0., 0.);; *)
let pship = nimg0 ();;
let t_ship = ref 0.;; (* timer on ship at the topo point (sec) *)
let t_earth = ref 0.;; (* timer on earth at the topo point (sec) *)
let ps = Array.make 1 img0;;
let vx = ref 0.;;
let vy = ref 0.;;

(* maintain the curve (in practice, the informations of the event of the ship being (E)) in the GR of earth (K) while showing the image in the GR of the velocity of the ship relative to earth (K') *)
let upd w h draw clear tf ship earth ts click_x click_y click_f draw_text draw_line =
  let (dx, dy) = begin
    let (_cx, _cy) = (click_x -. w/.2., click_y -. h/.2.) in
    (_cx /. (sqrt ((_cx *. _cx)+.(_cy *. _cy))), _cy /. (sqrt ((_cx *. _cx)+.(_cy *. _cy))))
  end in
  let lambda _ = 1./.sqrt (1. -. (!vx *. !vx +. !vy *. !vy)/.(cc*.cc)) in
  let tf {k1; k2; k3; k4; b1; b2} = tf k1 k2 k3 k4 b1 b2 in
  let draw img d = draw img (d.x -. d.w/.2.) (d.y -. d.h/.2.) d.w d.h; in

  (* draw a line with two ends points under effect but not width *)
  let draw_line eff x1 y1 x2 y2 =
    let {k1;k2;k3;k4;b1;b2} = eff in
    id |> tf;
    draw_line (k1*.x1+.k3*.y1+.b1) (k2*.x1+.k4*.y1+.b2) (k1*.x2+.k3*.y2+.b1) (k2*.x2+.k4*.y2+.b2);
  in

  (* the 2 lower rows of the matrix of lorentz transformation *)
  let mat_vec _ =
    let lambda = lambda () in
    let v = ((!vx*. !vx)+.(!vy*. !vy)) in
      if v = 0. then
        (0., 0., 1., 0., 0., 1.)
      else let v = 1./.v in (
      -.lambda *. !vx *. dcc,
      -.lambda *. !vy *. dcc,
      1.+.(lambda-.1.)*.(!vx*. !vx)*.v,
      (lambda-.1.)*.(!vx*. !vy)*.v,
      (lambda-.1.)*.(!vx*. !vy)*.v,
      1.+.(lambda-.1.)*.(!vy*. !vy)*.v
      )
  in

  (* get the x y of ship in K' *)
  let getxy _ =
    let (a, b, c, d, e, f) = mat_vec () in 
    (a*. !t_earth+.c*.pship.x+.e*.pship.y, b*. !t_earth+.d*.pship.x+.f*.pship.y)
  in

  (* get transformation from fix point in K to K' with t'=t_fit which is of E in K' *)
  let tv_earth _ =
    let lambda = lambda () in
    let t_fit = lambda *. (!t_earth -. !vx*.dcc*.pship.x -. !vy*.dcc*.pship.y) in
    let (kx, ky, _b) = (!vx*.dcc, !vy*.dcc, t_fit/.lambda) in
    let (a, b, c, d, e, f) = mat_vec () in {
      k1=kx*.a+.c;k3=ky*.a+.e;b1=_b*.a;
      k2=kx*.b+.d;k4=ky*.b+.f;b2=_b*.b;
    }
  in

  (* draw the universe in K' *)
  let show _ =
    clear ();
    let (px, py) = getxy () in
    let r = rk *. min w h in
    let t = {k1=r;k2=0.;k3=0.;k4=r;b1=w/.2. -. r *. px;b2=h/.2. -. r *. py;} in
    let lorentz = tv_earth () in
    let eff = lorentz |> comb t in
    eff |> tf;
    draw earth ps.(0);
    draw_line eff ps.(0).x ps.(0).y pship.x pship.y;
    let adj = {id with b1 = w/.2.;b2 = h/.2.} in
    let rot = {id with k1 = -.dy;k2 = dx;k3 = -.dx;k4 = -.dy;} in
    {id with k1=r;k4=r} |> comb rot |> comb adj |> tf;
    draw ship {pship with x = 0.;y = 0.};
  in

  let init _ =
    let tr = 1.0066 in
    ps.(0) <- {x= 0.;y= 0.;w=2.*.tr;h=2.*.tr};
    pship.w <- fst ship_size; pship.h <- snd ship_size;
    pship.x <- 0.; pship.y <- 0.;
    show ();
  in

  let go _ =
    let dt = (ts/.1000. -. !t_ship)*. lambda () in
    t_earth := !t_earth +. dt;
    pship.x <- pship.x +. dt *. !vx;
    pship.y <- pship.y +. dt *. !vy;
    t_ship := ts/.1000.;
  in

  if !t_ship = 0. then init ();
  go ();

  if click_f then begin
    vx := !vx +. dx *. inc;
    vy := !vy +. dy *. inc;
    let l = sqrt (!vx *. !vx +. !vy *. !vy) in
    if l > cc/.2. then begin
      vx := !vx /. l *. cc /. 2.;
      vy := !vy /. l *. cc /. 2.;
    end;
  end;
  show ();
  tf id;
  (* how to calculate the timer of earth in K' (t' of E)? we solve the equation L(t, 0, 0) = t' where L is the lorentz transformation from a event in K to a time in K' and (0, 0) is the location of all time of earth in K *)
  draw_text (Printf.sprintf "Earth Timer : %.2f Ship Timer : %.2f" (1. *. !t_earth -. !vx*.dcc*.pship.x -. !vy*.dcc*.pship.y) (!t_ship));
;;

(* let _ = *)
Js.export "oc"
  (object%js
     method upd = upd
   end);;