function onLoad() {
	const startBtn = document.getElementById("start-button")
	startBtn.addEventListener('click', start_game)
	console.log("ONLOAD")
}

// Returned value is --
//local ActionResult = {
	//game_state = GameState,
	//new_player_blocks = {},
	//new_computer_blocks = {},
//}

function start_game() {
	console.log("Start game")
	const myField = document.getElementById("player-field")
	const computerField = document.getElementById("computer-field")
	fetch('/start')
		.then(function(response) {
			return response.json();
		})
		.then(function(json) {
			console.log(json)
			createField(
				myField,
				json.player
			)
			createField(
				computerField,
				json.computer
			)
		});
}

// TODO
// Rather than maullay appending elements,
// Consider using insertAdjacent for simple dom parsing and addition
function createField(elem, blocks) {
	let htmlString = ""
	for (let i = 0, len = blocks[1].length; i < len; i++) {
		htmlString += `<div class="row">`
		for (let j = 0, len = blocks.length; j < len; j++) {
			htmlString += `<div class="block ${blocks[j][i]}"></div>`
		}
		htmlString += "</div>"
	}
	elem.insertAdjacentHTML('beforeend',htmlString)
}

// TODO
// Demo representation of final result
//<div id="target">
	//<div class="row">
		//<div class="block"></div>
		//<div class="block"></div>
		//<div class="block"></div>
		//<div class="block"></div>
	//</div>
//</div>
