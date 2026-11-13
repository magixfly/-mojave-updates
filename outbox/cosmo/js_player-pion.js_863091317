var player_pion_params = {
	current_url: null,
	connected: false,
	pc: null,
	socket: null,
	interval: null
}

$(document).ready(function() {

	var player_mode = parseInt(Cookies.get('video_player_mode'));
	if (isNaN(player_mode)) player_mode = 1;
	if (player_mode != 2) return;

	let wsProto = "ws";
	if (window.location.protocol != "http:") wsProto += "s";
	var url = wsProto + `://${window.location.host}:` + 8098 + `/websocket`;

	/// Very dirty hack
	sendStringCommand('pion-main-camera');
	setInterval(function() {
		sendStringCommand('pion-main-camera');
	}, 1000);

	PlayerPionStart(url);
});

function PlayerPionStart(url) {
	player_pion_params.current_url = url;
	if (player_pion_params.interval != null) clearInterval(player_pion_params.interval);
	player_pion_params.interval = setInterval(PlayerPionRun, 5000);
	PlayerPionRun();
}

function PlayerPionRun() {

	if (player_pion_params.connected) {
		return;
	}

	if (player_pion_params.pc != null) {
		player_pion_params.pc.close();
		player_pion_params.pc = null;
	}

	var configuration = {
		iceServers: [
			/*{ urls: "stun:stun.l.google.com:19302" }*/
		],
	};

	player_pion_params.pc = new RTCPeerConnection(configuration);

	player_pion_params.pc.onconnectionstatechange = (e) => onPeerConnectionStateChanged(player_pion_params.pc);
	player_pion_params.pc.oniceconnectionstatechange = (e) => onIceConnectionStateChanged(player_pion_params.pc.iceConnectionState);
	player_pion_params.pc.onicegatheringstatechange = (e) => onIceGatheringStateChanged(player_pion_params.pc.iceGatheringState);

	// Offer to receive 1 audio, and 2 video tracks
	player_pion_params.pc.addTransceiver("video", { direction: "sendrecv" });

	player_pion_params.pc.ontrack = function (event) {
		document.getElementById('video_element').srcObject = event.streams[0];
	};

	player_pion_params.pc.onicecandidate = (e) => {
		if (e.candidate && e.candidate.candidate !== "") {
			player_pion_params.socket.send(JSON.stringify(e.candidate));
		}
	};

	if (player_pion_params.socket != null) {
		try { if (!player_pion_params.socket.connected) player_pion_params.socket.close(); } catch (ex) {}
		player_pion_params.socket = null;
	}

	player_pion_params.socket = new WebSocket(player_pion_params.current_url);

	player_pion_params.socket.onopen = () => {
		onConnected();

		player_pion_params.pc.createOffer().then((offer) => {
			player_pion_params.pc.setLocalDescription(offer);
			player_pion_params.socket.send(JSON.stringify(offer));
		});
	};

	player_pion_params.socket.onerror = () => {
		onDisconnected();
	};

	player_pion_params.socket.onclose = () => {
		onDisconnected();
	};

	player_pion_params.socket.onmessage = (e) => {
		let msg = JSON.parse(e.data);
		if (!msg) return console.log("failed to parse msg");

		if (msg.candidate) {
			player_pion_params.pc.addIceCandidate(msg);
		} else {
			player_pion_params.pc.setRemoteDescription(msg);
		}
	};

}

function onConnected() {
	console.log('onConnected');
	player_pion_params.connected = true;
	//$("body").css('background-image','none');
	$("#video_container").css("display", "block");
	$("#video_element").css("display", "block");
}

function onDisconnected() {
	console.log('onDisconnected');
	player_pion_params.connected = false;
	//$("body").css('background-image','block');
	$("#video_element").css("display", "none");
}

function onPeerConnectionStateChanged(peerConnection) {
	var state = peerConnection.iceConnectionState;

	//console.log('onPeerConnectionStateChanged: ' + state);

	/*if (state == "connected") {
		console.log('peer connected ' + this.url + ' node ' + this.node);
	}

	if (state == "disconnected") {
		console.log('peer disconnected ' + this.url + ' node ' + this.node);
		connected = false;
	}*/
}

function onIceConnectionStateChanged(state) {
	//console.log('onIceConnectionStateChanged: ' + state);
}

function onIceGatheringStateChanged(state) {
	//console.log('onIceGatheringStateChanged: ' + state);
}
