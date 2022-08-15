open Js_of_ocaml;;

let rk = 0.4;;
let ship_size = (0.1/.rk, 0.138/.rk);;
(* let cc = 47055.7931251;; *)
let cc = 0.8;;
let dcc = 1./.(cc*.cc);;
(* let inc = cc/.1000000.;; *)
let inc = cc/.30.;;
let inc_set = cc/.3.;;

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

let add i1 i2 =
  {x=i1.x+.i2.x;y=i1.y+.i2.y;w=i1.w+.i2.w;h=i1.h+.i2.h};;

let mul k i =
  {x=k*.i.x;y=k*.i.y;w=k*.i.w;h=k*.i.h};;

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

let app t (x, y) =
  (t.k1*.x+.t.k3*.y+.t.b1, t.k2*.x+.t.k4*.y+.t.b2);;

let print_tv t =
  Printf.printf "tv: %f %f %f %f %f %f\n" t.k1 t.k2 t.k3 t.k4 t.b1 t.b2;;

(* let pship : vector ref = ref (0., 0.);; *)
let pship = nimg0 ();;
let t_ship = ref 0.;; (* timer on ship at the topo point (millisec) *)
let t_earth = ref 0.;; (* timer on earth at the topo point (sec) *)
let ps = Array.make 1 img0;;
let vx = ref 0.;;
let vy = ref 0.;;

(* maintain the curve in the GR of earth while showing the image in the GR of the ship *)
let upd w h draw clear tf ship earth ts click_x click_y click_f draw_text draw_line =
  let _cx = click_x -. w/.2. in
  let _cy = click_y -. h/.2. in
  let dx = _cx /. (sqrt ((_cx *. _cx)+.(_cy *. _cy))) in
  let dy = _cy /. (sqrt ((_cx *. _cx)+.(_cy *. _cy))) in
  let lambda _ = 1./.sqrt (1. -. (!vx *. !vx +. !vy *. !vy)/.(cc*.cc)) in
  let tf {k1; k2; k3; k4; b1; b2} = tf k1 k2 k3 k4 b1 b2 in
  let draw img d = draw img (d.x -. d.w/.2.) (d.y -. d.h/.2.) d.w d.h; in
  let draw_line eff x1 y1 x2 y2 =
    let {k1;k2;k3;k4;b1;b2} = eff in
    id |> tf;
    draw_line (k1*.x1+.k3*.y1+.b1) (k2*.x1+.k4*.y1+.b2) (k1*.x2+.k3*.y2+.b1) (k2*.x2+.k4*.y2+.b2);
  in

  (* the 2 lower rows *)
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
  
  (* get the x y of ship in its current GR *)
  let getxy _ =
    let lambda = lambda () in
    let (a, b, c, d, e, f) = mat_vec () in 
    (a*. !t_earth+.c*.pship.x+.e*.pship.y, b*. !t_earth+.d*.pship.x+.f*.pship.y)
  in

  let tv_earth _ =
    let lambda = lambda () in
    let t_fit = lambda *. (!t_earth -. !vx*.dcc*.pship.x -. !vy*.dcc*.pship.y) in
    let (kx, ky, _b) = (!vx*.dcc, !vy*.dcc, t_fit/.lambda) in
    let (a, b, c, d, e, f) = mat_vec () in {
      k1=kx*.a+.c;k3=ky*.a+.e;b1=_b*.a;
      k2=kx*.b+.d;k4=ky*.b+.f;b2=_b*.b;
    }
  in

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
    let dt = (ts -. !t_ship)*. lambda () /.1000. in
    t_earth := !t_earth +. dt;
    pship.x <- pship.x +. dt *. !vx;
    pship.y <- pship.y +. dt *. !vy;
    t_ship := ts;
  in

  if !t_ship = 0. then init ();
  go ();

  if click_f then begin
    (* vx := dx *. inc_set;
    vy := dy *. inc_set; *)
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
  draw_text (Printf.sprintf "Earth Timer : %.2f Ship Timer : %.2f" (1. *. !t_earth -. !vx*.dcc*.pship.x -. !vy*.dcc*.pship.y) (!t_ship/.1000.));
;;

(* let _ = *)
Js.export "oc"
  (object%js
     method upd = upd
   end);;