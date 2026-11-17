var haveEvents = 'ongamepadconnected' in window;
var controllers = {};

var gamepad_enable = false;
var gamepad_name = "";
var gamepad_index = -1;
var gamepad_lastTimestamp = 0;


$(document).ready(function() {
	gamepad_name = Cookies.get('use_gamepad_name');
	$("#browser_gamepad_enabled").prop('checked', Cookies.get('use_gamepad') == 1 ? 'checked' : '');

	$("#browser_gamepad_enabled").on("change", function(e) {
		var state = $(this).prop('checked');
		Cookies.set('use_gamepad', state ? 1 : 0, { expires: 365 });
		document.location.reload();
	});

	$("#available_gamepads_list").on("change", function(e) {
		var name = $(this).val();
		Cookies.set('use_gamepad_name', name, { expires: 365 });
		document.location.reload();
	});


	if (Cookies.get('use_gamepad') != 1) {
		console.log('gamepad disabled');
		show_log('gamepad disabled');
		gamepad_enable = false;
	} else {
		console.log('gamepad enabled ' + gamepad_name);
		show_log('gamepad enabled ' + gamepad_name);
		gamepad_enable = true;
	}

	window.addEventListener("gamepadconnected", connecthandler);
	window.addEventListener("gamepaddisconnected", disconnecthandler);
	if (!haveEvents) {
		setInterval(scangamepads, 500);
	}
});


function ToggleGamepadSettingsWindow() {
	if ($("#gamepad_settings_container").css("display") == "none") {
		SetGamepadSettingsWindowState(true);
	} else {
		SetGamepadSettingsWindowState(false);
	}
}

function SetGamepadSettingsWindowState(state) {
	$("#gamepad_settings_container").css("display", state ? "block" : "none");
}


function updateStatus() {

	if (!haveEvents) scangamepads();

	if (!gamepad_enable) {
		requestAnimationFrame(updateStatus);
		return;
	}

	var i, j;

	const max_axis = 16;
	var axis_buffer = new Uint8Array(max_axis * 2);
	var buttons_state = 0;

	for (j in controllers) {
		var controller = controllers[j];
		if (gamepad_index != controller.index) continue;

		buttons_state = 0;
		for (i = 0; i < controller.buttons.length; i++) {
			var btn = controller.buttons[i];

			if (typeof(btn) == "object") {
				if (btn.pressed) {
					buttons_state |= 1 << i;
					//console.log(i + ' ' + btn.pressed);
				}
			}
		}

		var len = controller.axes.length;
		if (len > max_axis) len = max_axis;
		for (i = 0; i < len; i++) {
			var value = parseInt(controller.axes[i] * 32767 + 32767);
			axis_buffer[i * 2] = value & 0xff;
			axis_buffer[i * 2 + 1] = (value >> 8) & 0xff;
		}

		sendJoystickBinary(axis_buffer, buttons_state);
	}

	requestAnimationFrame(updateStatus);
}


function connecthandler(e) {
	addgamepad(e.gamepad);
}


function addgamepad(gamepad) {
	//$("#current_gamepad_name").html(gamepad.id);
	show_log("append gamepad " + gamepad.id);
	$("#available_gamepads_list").append(new Option(gamepad.id, gamepad.id));

	if (gamepad.id == gamepad_name) {
		$("#available_gamepads_list").val(gamepad_name);
		gamepad_index = gamepad.index;
	}

	controllers[gamepad.index] = gamepad;
	requestAnimationFrame(updateStatus);
}


function disconnecthandler(e) {
	removegamepad(e.gamepad);
}


function removegamepad(gamepad) {
	delete controllers[gamepad.index];
}


function scangamepads() {
	var gamepads = navigator.getGamepads ? navigator.getGamepads() : (navigator.webkitGetGamepads ? navigator.webkitGetGamepads() : []);
	for (var i = 0; i < gamepads.length; i++) {
		if (gamepads[i]) {
			if (gamepads[i].index in controllers) {
				controllers[gamepads[i].index] = gamepads[i];
			} else {
				addgamepad(gamepads[i]);
			}
		}
	}
}


function sendJoystickBinary(axis_buffer, buttons) {

	/*var str = "";
	for (var i = 0; i < axis_buffer.length / 2; i++) {
		var val = axis_buffer[i * 2] + (axis_buffer[i * 2 + 1 ] << 8);
		str += val + " ";
	}
	console.log(str);*/

	/// Reduce messages
	var d = new Date();
	var dt = d.getTime() - gamepad_lastTimestamp;
	if (dt < 50) return;
	gamepad_lastTimestamp = d.getTime();
	d = null;

	var header = new Uint8Array(6);
	header[0] = PACKET_ID.PACKET_CLIENT_BINARY_DATA;
	header[1] = 22;
	header[2] = buttons & 0xff;
	header[3] = (buttons >> 8) & 0xff;
	header[4] = 0; /// for future use
	header[5] = 0; /// for future use

	var msg = new Uint8Array(header.length + axis_buffer.length);
	msg.set(header);	
	msg.set(axis_buffer, header.length);	
	//console.log(msg);
	ws.send(msg, msg.length);

	buf = null;
}
