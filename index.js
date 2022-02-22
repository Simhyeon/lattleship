$pause(true) // Rad macro operation

let connectionId  = ""
let onStart       = false
let onRequest     = false
let discInterval  = null // Disconnect Interval
const BlockStates = ["blank", "occupied", "attacked", "cleared"]

function resetEnv() {
	// Reset connection id
	connectionId = "" 
	onStart      = false
	onRequest    = false
	clearInterval(discInterval)
}

// tv is bool
function setBlur(tv) {
	const elem = document.getElementById("panel")
	if (tv) { // true
		elem.classList.add("blurred")
	} else {  // false
		elem.classList.remove("blurred")
	}
}

function disableGame(alertMsg) {
	resetEnv()
	setBlur(true)
	window.alert(alertMsg)
}

function onLoad() {
	const startBtn = document.getElementById("start-button")
	startBtn.addEventListener('click', startGame)
}

function isBusy() {
	return onRequest || onStart
}

// This sets interval
function refreshConnection() {
	discInterval = setInterval(() => {
		console.log("Refreshing connection")
		fetch("/refresh", {
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
			},
			body: new URLSearchParams({
				'id': connectionId,
			})
		}).catch(error => {
			disableGame(`Failed to connect to server\nErr : ${error}`)
		})
	}, 30000);
}

function startGame() {
	if (isBusy()) return;
	console.log("Start game");
	// Clear everything before assigning field
	clearField();
	setBlur(false);
	const myField = document.getElementById("player-field");
	const computerField = document.getElementById("computer-field");
	onStart = true;
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
		}).catch(error => {
			disableGame(`Failed to connect to server\nErr : ${error}`)
		});

	refreshConnection();
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

// Send /pick POST request with params
// TODO
// Check if server timeout is returned
function attackBlock(event) {
	if (connectionId == "") return
	if (isBusy()) return;
	const btn = event.target
	if (btn.classList.contains('blank')) {
		// Don't request if previous request is on load
		onRequest = true;

		// Send request
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
			if (json.winner != undefined) { // Either undefined or winner
				// Game end
				gameEnd(json.winner)
			} 
		}).catch(error => {
			disableGame(`Failed to connect to server\nErr : ${error}`)
		});

		// End reqeust flow
		onRequest = false
	}
}

// winner is a string
function gameEnd(winner) {
	resetEnv()
	setBlur(true)
	window.alert(`${winner} won.`)
}

$pause(false) // Rad macro operation
