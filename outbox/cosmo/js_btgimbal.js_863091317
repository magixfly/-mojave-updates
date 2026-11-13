var btGimbalCheckInterval = null;
var btGimbalWindowStartpoint = {}
var btGimbalWindowMouseDown = false;

var statusTimestamp = 0;

var btGimbalStatus = {
	gimbal_app_type: 0,
	device_connected: false,
	pan: 0.0, tilt: 0.0, roll: 0.0,
	battery_level: 0,
	mode: 0,
	gimbal_model: 0
}


$(document).ready(function() {

	$('#btgimbal_control_header').on("touchstart", bggimbalWindowOnTouchStart);
	$('#btgimbal_control_header').on("touchend", bggimbalWindowOnTouchEnd);
	$('#btgimbal_control_header').on("touchmove", bggimbalWindowOnTouchMove);
	$('#btgimbal_control_header').on("mousedown", bggimbalWindowOnStartMove);
	$('#btgimbal_control_header').on("mouseup", bggimbalWindowOnEndMove);
	$('#btgimbal_control_header').on("mouseleave", bggimbalWindowOnEndMove);
	$('#btgimbal_control_header').on("mousemove", bggimbalWindowOnMove);

	function bggimbalWindowOnTouchStart(event) {
		event.preventDefault();
		btGimbalWindowMouseDown = true;
		btGimbalWindowStartpoint.x = event.originalEvent.touches[0].pageX;
	 	btGimbalWindowStartpoint.y = event.originalEvent.touches[0].pageY;
	}

	function bggimbalWindowOnTouchEnd(event) {
		event.preventDefault();
		btGimbalWindowMouseDown = false;
	}

	function bggimbalWindowOnTouchMove(event) {
		event.preventDefault();
		if (!btGimbalWindowMouseDown) return;
		MoveBtGimbalWindow($(this), event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
	}

	function bggimbalWindowOnStartMove(event) {
		event.preventDefault();
		btGimbalWindowMouseDown = true;
		btGimbalWindowStartpoint.x = event.pageX;
	 	btGimbalWindowStartpoint.y = event.pageY;
	}

	function bggimbalWindowOnEndMove(event) {
		event.preventDefault();
		btGimbalWindowMouseDown = false;
	}

	function bggimbalWindowOnMove(event) {
		event.preventDefault();
		if (!btGimbalWindowMouseDown) return;
		MoveBtGimbalWindow($(this), event.pageX, event.pageY);
	}

	function MoveBtGimbalWindow(obj, x, y) {
		try {
			var obj = $("#btgimbal_control_area");
			var old_x = parseInt(obj.css("left"));
			var old_y = parseInt(obj.css("top"));
			obj.css("left", old_x + (x - btGimbalWindowStartpoint.x));
			obj.css("top", old_y + (y - btGimbalWindowStartpoint.y));
		} catch (e) { console.log(e); }

		btGimbalWindowStartpoint.x = x;
		btGimbalWindowStartpoint.y = y;
	}

	$('#btgimbal_reset_button').on('mouseup', function(e) {
		BtGimbalReset();
		e.preventDefault();
	});
	$('#btgimbal_reset_button').on('touchend', function(e) {
		BtGimbalReset();
		e.preventDefault();
	});

	$('#btgimbal_mode1_button').on('mouseup', function(e) {
		BtGimbalSetMode(0);
		e.preventDefault();
	});
	$('#btgimbal_mode1_button').on('touchend', function(e) {
		BtGimbalSetMode(0);
		e.preventDefault();
	});

	$('#btgimbal_mode2_button').on('mouseup', function(e) {
		BtGimbalSetMode(1);
		e.preventDefault();
	});
	$('#btgimbal_mode2_button').on('touchend', function(e) {
		BtGimbalSetMode(1);
		e.preventDefault();
	});

	$('#btgimbal_mode3_button').on('mouseup', function(e) {
		BtGimbalSetMode(2);
		e.preventDefault();
	});
	$('#btgimbal_mode3_button').on('touchend', function(e) {
		BtGimbalSetMode(2);
		e.preventDefault();
	});

});

function BtGimbalParseStatus(data) {
	if (data.Length < 11) return;
	//console.log(data);

	if (btGimbalCheckInterval == null) {
		btGimbalCheckInterval = setInterval(BtGimbalCheck, 1000);
	}

	var offset = 1;

	var newStatusGimbalConnected = data[offset + 1] == 1;
	if (newStatusGimbalConnected && !btGimbalStatus.device_connected) {
		onBtGimbalFound();
	}

	statusTimestamp = new Date().getTime();

	btGimbalStatus.gimbal_app_type = data[offset + 0];
	btGimbalStatus.device_connected = data[offset + 1] == 1;
	btGimbalStatus.device_model = data[offset + 2];

	//btGimbalStatus.device_model_str = substrFromBytes(data, 3, 20);
	//btGimbalStatus.device_model_str = bin2String(data, 3, 20);
	//console.log('btGimbalStatus.device_model_str ' + btGimbalStatus.device_model_str);

	btGimbalStatus.mode = data[offset + 23];

	btGimbalStatus.pan = (Int16(data[offset + 24] + (data[offset + 25] << 8))) / 10.0;
	btGimbalStatus.tilt = (Int16(data[offset + 26] + (data[offset + 27] << 8))) / 10.0;
	btGimbalStatus.roll = (Int16(data[offset + 28] + (data[offset + 29] << 8))) / 10.0;
	btGimbalStatus.current = ((Int16)(data[offset + 30] + (data[offset + 31] << 8))) / 100.0;
	btGimbalStatus.voltage = ((Int16)(data[offset + 32] + (data[offset + 33] << 8))) / 100.0;
	btGimbalStatus.battery_level = data[offset + 34];
	btGimbalStatus.battery_charging = data[offset + 35] == 1;

	$("#btgimbal_battery_field").html(btGimbalStatus.battery_level + "%");
	if (btGimbalStatus.battery_level < 15) {
		$("#btgimbal_battery_field").css('color', 'red');
	} else {
		$("#btgimbal_battery_field").css('color', 'lightgreen');
	}

	$("#btgimbal_position_field").html(btGimbalStatus.pan.toFixed(1) + " " + btGimbalStatus.tilt.toFixed(1) + " " + btGimbalStatus.roll.toFixed(1));

	switch (btGimbalStatus.mode) {
		case 0:
			/// Follow
			$("#btgimbal_mode2_button").css('color', 'gray');
			$("#btgimbal_mode3_button").css('color', 'gray');
			$("#btgimbal_mode1_button").css('color', 'yellow');
		break;
		case 1:
			/// Lock
			$("#btgimbal_mode1_button").css('color', 'gray');
			$("#btgimbal_mode3_button").css('color', 'gray');
			$("#btgimbal_mode2_button").css('color', 'yellow');
		break;
		case 2:
			/// Full
			$("#btgimbal_mode1_button").css('color', 'gray');
			$("#btgimbal_mode2_button").css('color', 'gray');
			$("#btgimbal_mode3_button").css('color', 'yellow');
		break;
	}

}


function onBtGimbalFound() {
	console.log('BT gimbal found');
	$('#btgimbal_control_area').css('display', 'block');
}


function onBtGimbalLost() {
	console.log('BT gimbal lost');
	$('#btgimbal_control_area').css('display', 'none');
}


function BtGimbalCheck() {
	if (statusTimestamp > 0) {
		var dt = new Date().getTime() - statusTimestamp;
		if (dt > 1000) {
			statusTimestamp = 0;
			btGimbalStatus.device_connected = 0;
			onBtGimbalLost();
		}
	}
}

function BtGimbalReset() {
	sendStringCommand("!{\"cmd\":\"position\",\"param\":\"normal\"}");
}

function BtGimbalSetMode(mode) {
	sendStringCommand("!{\"cmd\":\"gimbal\",\"param\":\"mode\",\"value\":\"" + mode + "\"}");
}


/*function substrFromBytes(buf, start, length)
{
    var byteArray = buf.slice(start, start+length).toString();
	return String.fromCharCode(...byteArray);
}

function bin2String(array, offset, len) {
  var result = "";
  for (var i = offset; i < offset + len; i++) {
    result += String.fromCharCode(parseInt(array[i], 2));
  }
  return result;
}*/