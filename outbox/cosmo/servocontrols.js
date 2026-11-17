var servoControlsCheckInterval = null;
var servoWindowStartpoint = {}
var servoWindowMouseDown = false;
var servoControlsStatus = {
	timestamp: 0
}

$(document).ready(function() {

	if (servoControlsCheckInterval == null) {
		servoControlsCheckInterval = setInterval(ServoControlsCheck, 1000);
	}

	var w = parseInt($("#joyDiv").css('width'));
	var h = parseInt($("#joyDiv").css('height'));

	/*var Joy1 = new JoyStick('joyDiv', {width:w, height:h}, function(stickData) {
	    //console.log(stickData.xPosition);
    	//console.log(stickData.yPosition);
	    //console.log(stickData.cardinalDirection);
    	//console.log(stickData.x);
	    //console.log(stickData.y);
	});*/

	$('#servo_control_header').on("touchstart", servoWindowOnTouchStart);
	$('#servo_control_header').on("touchend", servoWindowOnTouchEnd);
	$('#servo_control_header').on("touchmove", servoWindowOnTouchMove);
	$('#servo_control_header').on("mousedown", servoWindowOnStartMove);
	$('#servo_control_header').on("mouseup", servoWindowOnEndMove);
	$('#servo_control_header').on("mouseleave", servoWindowOnEndMove);
	$('#servo_control_header').on("mousemove", servoWindowOnMove);

	function servoWindowOnTouchStart(event) {
		event.preventDefault();
		servoWindowMouseDown = true;
		servoWindowStartpoint.x = event.originalEvent.touches[0].pageX;
	 	servoWindowStartpoint.y = event.originalEvent.touches[0].pageY;
	}

	function servoWindowOnTouchEnd(event) {
		event.preventDefault();
		servoWindowMouseDown = false;
	}

	function servoWindowOnTouchMove(event) {
		event.preventDefault();
		if (!servoWindowMouseDown) return;
		MoveServoWindow($(this), event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
	}

	function servoWindowOnStartMove(event) {
		event.preventDefault();
		servoWindowMouseDown = true;
		servoWindowStartpoint.x = event.pageX;
	 	servoWindowStartpoint.y = event.pageY;
	}

	function servoWindowOnEndMove(event) {
		event.preventDefault();
		servoWindowMouseDown = false;
	}

	function servoWindowOnMove(event) {
		event.preventDefault();
		if (!servoWindowMouseDown) return;
		MoveServoWindow($(this), event.pageX, event.pageY);
	}

	function MoveServoWindow(obj, x, y) {
		try {
			var obj = $("#servo_control_area");
			var old_x = parseInt(obj.css("left"));
			var old_y = parseInt(obj.css("top"));
			obj.css("left", old_x + (x - servoWindowStartpoint.x));
			obj.css("top", old_y + (y - servoWindowStartpoint.y));
		} catch (e) { console.log(e); }

		servoWindowStartpoint.x = x;
		servoWindowStartpoint.y = y;
	}


	$(".servo_slider").on("input", function(e) {
		e.preventDefault();
		var num = $(this).attr("num") - 1;
		var value = parseInt((($(this).val() - 50) / 50.0) * 32767);
		sendBinaryCommand(10, num, value, 0);
	});

});

function ServoParseStatus(data) {
	//if (data.Length < 25) return;
	//console.log(data);
}


function onServoControlsFound() {
	console.log('Servo control found');
	$('#servo_control_area').css('display', 'block');
}


function onServoControlsLost() {
	console.log('Servo controls lost');
	$('#servo_control_area').css('display', 'none');
}


function ServoControlsCheck() {
	if (servoControlsStatus.timestamp > 0) {
		var dt = new Date().getTime() - servoControlsStatus.timestamp;
		if (dt > 3000) {
			servoControlsStatus.timestamp = 0;
			onServoControlsLost();
		}
	}
}

function ServoControlsParse(enabled, channels_bits, joystick_type, values) {
	if (!enabled) return;
	if (servoControlsStatus.timestamp == 0) onServoControlsFound();
	servoControlsStatus.timestamp = new Date().getTime();

	$("#servo_slider_1").css("display", channels_bits & 0x01 == 1 ? "inline" : "none");
	$("#servo_slider_2").css("display", (channels_bits >> 1) & 0x01 == 1 ? "inline" : "none");
	$("#servo_slider_3").css("display", (channels_bits >> 2) & 0x01 == 1 ? "inline" : "none");
	$("#servo_slider_4").css("display", (channels_bits >> 3) & 0x01 == 1 ? "inline" : "none");

	$("#servo_slider_1").val(values[0]);
	$("#servo_slider_2").val(values[1]);
	$("#servo_slider_3").val(values[2]);
	$("#servo_slider_4").val(values[3]);
}
