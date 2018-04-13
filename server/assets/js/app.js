import { Socket } from "phoenix"

let socket = new Socket("/socket", {})
socket.connect()
console.log(socket)


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
    alert("ok")
  }, 5000)
})

  channel.on("tick", (p) => {
  console.log(p)

  timecode.innerHTML = p.timecode
})

document.getElementById("start").addEventListener("click", () => {
  var id = "final"
  document.getElementById("start").style.display = "none";

  //  var audio = document.createElement("audio")
  //  audio.oncanplaythrough = function(){
  //    console.log(1)
  //    audio.play();
  channel.push("start", {id: id})
  //}
  //  audio.src = "/audio/" + id + ".wav"
})
