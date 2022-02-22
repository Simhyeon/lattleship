$pause(true) // Rad macro operation

let connectionId  = ""
let onStart       = false
let onRequest     = false
let lastTime      = null
const BlockStates = ["blank", "occupied", "attacked", "cleared"]

function onLoad() {
	const startBtn = document.getElementById("start-button")
	startBtn.addEventListener('click', startGame)
}

// Returned value of /pick api --
//local ActionResult = {
	//winner = "player" | "computer",
	//player = {
	//		state = STRING
	//		row   = NUM
	//		col   = NUM
	//},
	//computer = <Same with new player>,
//}

function isBusy() {
	return onRequest || onStart
}

// TODO
// Not only return boolean but make it to show a pop up menu
function checkDisconnected(current_time) {
	if ( (current_time - lastTime) / 1000  >= 60 ) {
		return true
	} else {
		return false
	}
}

function startGame() {
	if (isBusy()) return;
	console.log("Start game")
	// Clear everything before assigning field
	clearField()
	const myField = document.getElementById("player-field")
	const computerField = document.getElementById("computer-field")
	onStart = true
	lastTime = Date.now();
	fetch('/start')
		.then((response) => {
			return response.json();
		})
		.then((json) => {
			connectionId = json.id
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

			// End start flow
			onStart = false
		});
}

function clearField() {
	const myField = document.getElementById("player-field")
	const computerField = document.getElementById("computer-field")

	// Remove all child elements if there are
	while (myField.firstChild) {
		myField.firstChild.remove()
	}
	while (computerField.firstChild) {
		computerField.firstChild.remove()
	}
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
		elem.addEventListener('click', attackBlock)
	})
}

function attackBlock(event) {
	if (connectionId == "") return
	if (isBusy()) return;
	const btn = event.target
	if (btn.classList.contains('blank')) {
		// Don't request if previous request is on load
		onRequest = true;

		fetch("/pick", {
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
			},
			body: new URLSearchParams({
				'id': connectionId,
				'row' : btn.dataset.row,
				'col' : btn.dataset.col,
			})
		}).then((response) => {
			return response.json();
		}).then((json) => {
			console.log(json)
			if (json.winner == undefined) { // Either undefined or winner
				const pBlock   = json.player
				const cBlock   = json.computer
				if (pBlock != undefined ) {
					const block = document.querySelector(`#player-field .b-${pBlock.row}${pBlock.col}`)
					block.classList.remove(...BlockStates)
					block.classList.add(pBlock.state)
				}
				if (cBlock != undefined ) {
					const block = document.querySelector(`#computer-field .b-${cBlock.row}${cBlock.col}`)
					block.classList.remove(...BlockStates)
					block.classList.add(cBlock.state)
				}
			} else {
				// Game end
				connectionId = "" // Reset connection id
				gameEnd(json.winner)
			}
		});

		// End reqeust flow
		onRequest = false
	}
}

// winner is string
function gameEnd(winner) {
	// TODO
	// Show pop up
}

$pause(false) // Rad macro operation
