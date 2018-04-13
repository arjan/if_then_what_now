import { Socket } from "phoenix"

let socket = new Socket("/socket", {})
socket.connect()

let started = false

let channel = socket.channel("audio", {})
channel.join()
                    .receive("ok", resp => { console.log("Joined successfully", resp) })
                    .receive("error", resp => { console.log("Unable to join", resp) })

var words = document.getElementById("words")
var timecode = document.getElementById("timecode")
var bottom = document.getElementById("bottom")

function cls(name, value) {
  value = Math.floor(10 * Math.max(0, Math.min(1, value)));
  return name + '-' + value + ' '
}

channel.on("word", (p) => {
  // normalize
  //  p.speed /= 2;
  //  p.volume /= 2;
  document.getElementById("start").style.display = "none";

  var span = document.createElement("span")
  span.innerHTML = p.word
  span.className = 'invisible ' + cls('volume', p.volume) + cls('pitch', p.pitch) + cls('speed', p.speed)
  words.appendChild(span)
  setTimeout(() => {
    span.classList.toggle('invisible', false)
    bottom.scrollIntoView({behavior: 'smooth'})
  }, 100)
})

channel.on("done", (p) => {
  setTimeout(function() {
    window.print();
    document.location.reload()
  }, 5000)
})

channel.on("tick", (p) => {
  console.log(p)

  timecode.innerHTML = p.timecode
})

function start() {
  started = true
  var id = "final"
  document.getElementById("start").style.display = "none";
  channel.push("start", {id: id})
}

document.getElementById("start").addEventListener("click", start)
document.addEventListener("keyup", (e) => {
  if (e.keyCode == 32 && !started) {
    start()
  }
})

if (document.location.hash) {
  document.body.classList.toggle(document.location.hash.substr(1), true)
}
