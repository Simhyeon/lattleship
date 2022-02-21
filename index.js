$pause(true)

let connection_id = ""
let resp = ""
const block_states = ["blank", "occupied", "attacked", "cleared"]

function onLoad() {
	const startBtn = document.getElementById("start-button")
	startBtn.addEventListener('click', start_game)
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
		.then((response) => {
			return response.json();
		})
		.then((json) => {
			connection_id = json.id
			createField(
				myField,
				json.player
			)
			createField(
				computerField,
				json.computer
			)

			// Add btn functionality
			addBtnEventListener()
		});
}

function createField(elem, blocks) {
	let htmlString = ""
	for (let i = 0, len = blocks[1].length; i < len; i++) {
		htmlString += `<div class="row">`
		for (let j = 0, len = blocks.length; j < len; j++) {
			const row = i + 1
			const col = j + 1
			htmlString += `<div class="block ${blocks[j][i]} b-${row}${col}" data-row="${row}" data-col="${col}"></div>`
		}
		htmlString += "</div>"
	}
	elem.insertAdjacentHTML('beforeend',htmlString)
}

function addBtnEventListener() {
	document.querySelectorAll('#computer-field .block').forEach(elem => {
		elem.addEventListener('click', attack_block)
	})
}

function attack_block(event) {
	const btn = event.target
	if (btn.classList.contains('blank')) {
		fetch("/pick", {
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
			},
			body: new URLSearchParams({
				'id': connection_id,
				'row' : btn.dataset.row,
				'col' : btn.dataset.col,
			})
		}).then((response) => {
			return response.json();
		}).then((json) => {
			console.log(json)
			if (json.state != "end") { // Either on or end
				const pBlock   = json.player
				const cBlock = json.computer
				if (pBlock != undefined ) {
					//console.log("Changed p block is ")
					//console.log(pBlock)
					const block = document.querySelector(`#player-field .b-${pBlock.row}${pBlock.col}`)
					block.classList.remove(...block_states)
					block.classList.add(pBlock.state)
				}
				if (cBlock != undefined ) {
					//console.log("Changed c block is ")
					//console.log(cBlock)
					const block = document.querySelector(`#computer-field .b-${cBlock.row}${cBlock.col}`)
					block.classList.remove(...block_states)
					block.classList.add(cBlock.state)
				}
			}
		});
	}
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

$pause(false)
