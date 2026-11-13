var ws = undefined;
var connected = false;

$(document).ready(function() {
	if(typeof(WebSocket)=="undefined") {
		// no websockets in this browser
	} else {
		tryConnect();
	}
});


function isConnected() {
	return connected;
}

function tryConnect() {
	setTimeout(tryConnect, 5000);
	if (connected) return;
	doConnect();
}


function doConnect() {
	if (ws != undefined) {
		ws.close();
		ws = undefined;
	}

	/// Start websockets connection
	ws = new WebSocket("ws://" + document.location.host + ":8081");
	ws.binaryType = "arraybuffer";

	ShowConnectionMessage("trying to connect...");

	ws.onmessage = function(event) {

		/// Parse telemetry
		parseTelemetry(event);
	}

	ws.onopen = function(event) {
		ShowConnectionMessage();
		connected = true;

		$("#top_panel").css("display", "block");
		$("#video_container").css("display", "block");
		//$("#video_canvas").css("display", "block");

		if (isDeviceSettingsWindowOpened()) ToggleDeviceSettingsWindow("");
	}

	ws.onerror = function(e) {
		ShowConnectionMessage("connection error");
		connected = false;

		$(".needhide").css('display','none');
		$("#top_panel").css("display", "none");
		$("#top_area").html("&nbsp;");
		$("#bottom_area").html("&nbsp;");
		$("#video_container").css("display", "none");
		//$("#video_canvas").css("display", "none");

		if (isDeviceSettingsWindowOpened()) ToggleDeviceSettingsWindow("");
	}

	ws.onclose = function() {
		if (connected) {
			ShowConnectionMessage("disconnected");
		} else {
			ShowConnectionMessage("connection failed");
		}

		connected = false;

		$(".needhide").css('display','none');
		$("#top_panel").css("display", "none");
		$("#top_area").html("&nbsp;");
		$("#bottom_area").html("&nbsp;");
		$("#video_container").css("display", "none");
		//$("#video_canvas").css("display", "none");

		if (isDeviceSettingsWindowOpened()) ToggleDeviceSettingsWindow("");
	}
}


function ShowConnectionMessage(text) {
	if (text == undefined) {
		$('#connectionmessage').html("");
		$('#connectionmessage').css("display","none");
	} else {
		$('#connectionmessage').html(text);
		$('#connectionmessage').css("display","block");
	}
}


function sendBinaryCommand(id, value1, value2, value3) {
	//console.log('sendBinaryCommand ' + value1 + ' ' + value2 + ' ' + value3);
	var buf = new Uint8Array(8);
	buf[0] = PACKET_ID.PACKET_CLIENT_BINARY_DATA;
	buf[1] = id;
	buf[2] = value1 & 0xff;
	buf[3] = (value1 >> 8) & 0xff;
	buf[4] = value2 & 0xff;
	buf[5] = (value2 >> 8) & 0xff;
	buf[6] = value3 & 0xff;
	buf[7] = (value3 >> 8) & 0xff;
	ws.send(buf, buf.length);
	buf = null;
}

function sendStringCommand(cmd) {
	if (!connected) return;
	//alert(cmd);
	ws.send(cmd);
}
