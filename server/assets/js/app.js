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

function cls(name, value) {
  value = Math.floor(10 * Math.max(0, Math.min(1, value)));
  return name + '-' + value + ' '
}

channel.on("word", (p) => {
  // normalize
  p.speed /= 2;
  p.volume /= 2;

  var span = document.createElement("span")
  span.innerHTML = p.word
  span.className = cls('volume', p.volume) + cls('pitch', p.pitch) + cls('speed', p.speed)
  words.appendChild(span)
})

channel.on("tick", (p) => {
  console.log(p)

  timecode.innerHTML = p.timecode
})

document.getElementById("start").addEventListener("click", () => {
  var id = "auke1"
  //  var audio = document.createElement("audio")
  //  audio.oncanplaythrough = function(){
  //    console.log(1)
  //    audio.play();
  channel.push("start", {id: id})
  //}
  //  audio.src = "/audio/" + id + ".wav"
})
