window.onload = main;

function width() { return window.innerWidth; }
function height() { return window.innerHeight; }
let click_x = 0;
let click_y = 0;
let click_f = false;

async function load_img(src) {
  let img = new Image();
  let loaded = new Promise((resolve, reject) => {
    img.addEventListener("load", () => {
      resolve(img);
    })
  })
  img.src = src;
  return await loaded;
}

async function main () {
  const canvas = document.createElement("canvas");
  document.body.append(canvas);
  canvas.width = width();
  canvas.height = height();
  const ctx = canvas.getContext("2d");
  function clear() {
    ctx.fillStyle = "#000000";
    ctx.fillRect(0, 0, width(), height());
  }
  function draw(img, x, y, w, h) {
    ctx.drawImage(img, x, y, w, h);
  }
  function tf(a, b, c, d, e, f) {
    ctx.setTransform(a, b, c, d, e, f);
  }
  function draw_text(s) {
    console.log(s.c);
    ctx.fillStyle = "#ffffff";
    ctx.fillText(s.c, 10, 50);
  }
  function draw_line(x1, y1, x2, y2) {
    ctx.strokeStyle = "#ffffff";
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
  }
  const ship = await load_img("src/ship.svg");
  const earth = await load_img("src/earth.svg");
  
  canvas.addEventListener("click", (e)=>{click_x=e.x; click_y=e.y;click_f=true;});
  
  await import("./redraw.bc.js");
  function loop(ts) {
    canvas.width = width();
    canvas.height = height();
    oc.upd(width(), height(), draw, clear, tf, ship, earth, ts, click_x, click_y, click_f, draw_text, draw_line);
    click_f = false;
    ctx.resetTransform();
    window.requestAnimationFrame(loop);
  }
  window.requestAnimationFrame(loop);
}