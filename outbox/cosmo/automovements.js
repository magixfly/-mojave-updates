var amWindowStartpoint = {}
var amWindowMouseDown = false;

$(document).ready(function() {

	$('#am_control_header').on("touchstart", amWindowOnTouchStart);
	$('#am_control_header').on("touchend", amWindowOnTouchEnd);
	$('#am_control_header').on("touchmove", amWindowOnTouchMove);
	$('#am_control_header').on("mousedown", amWindowOnStartMove);
	$('#am_control_header').on("mouseup", amWindowOnEndMove);
	$('#am_control_header').on("mouseleave", amWindowOnEndMove);
	$('#am_control_header').on("mousemove", amWindowOnMove);

	function amWindowOnTouchStart(event) {
		event.preventDefault();
		amWindowMouseDown = true;
		amWindowStartpoint.x = event.originalEvent.touches[0].pageX;
	 	amWindowStartpoint.y = event.originalEvent.touches[0].pageY;
	}

	function amWindowOnTouchEnd(event) {
		event.preventDefault();
		amWindowMouseDown = false;
	}

	function amWindowOnTouchMove(event) {
		event.preventDefault();
		if (!amWindowMouseDown) return;
		MoveAmWindow($(this), event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
	}

	function amWindowOnStartMove(event) {
		event.preventDefault();
		amWindowMouseDown = true;
		amWindowStartpoint.x = event.pageX;
	 	amWindowStartpoint.y = event.pageY;
	}

	function amWindowOnEndMove(event) {
		event.preventDefault();
		amWindowMouseDown = false;
	}

	function amWindowOnMove(event) {
		event.preventDefault();
		if (!amWindowMouseDown) return;
		MoveAmWindow($(this), event.pageX, event.pageY);
	}

	function MoveAmWindow(obj, x, y) {
		try {
			var obj = $("#am_control_area");
			var old_x = parseInt(obj.css("left"));
			var old_y = parseInt(obj.css("top"));
			obj.css("left", old_x + (x - amWindowStartpoint.x));
			obj.css("top", old_y + (y - amWindowStartpoint.y));
		} catch (e) { console.log(e); }

		amWindowStartpoint.x = x;
		amWindowStartpoint.y = y;
	}

	$('#am_settings_button').on('click', function() {
		ToggleDeviceSettingsWindow("Auto movement");
	});

	$('#am_loop_enabled').on('change', function(e) {
		e.preventDefault();
		var state = $(this).prop('checked') ? "1" : "0";
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"setstate","value2":"' + state + '","value3":""}');
	});
	$('#am_photo_enabled').on('change', function(e) {
		e.preventDefault();
		var state = $(this).prop('checked') ? "1" : "0";
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"setphoto","value2":"' + state + '","value3":""}');
	});
	$('#am_smooth_enabled').on('change', function(e) {
		e.preventDefault();
		var state = $(this).prop('checked') ? "1" : "0";
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"setsmooth","value2":"' + state + '","value3":""}');
	});

	$('#am_speed_option').on('change', function(e) {
		e.preventDefault();
		var number = $(this).prop('selectedIndex');
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"setsmoothspeed","value2":"' + number + '","value3":""}');
	});

	$('#am_position_option').on('change', function(e) {
		e.preventDefault();
		var number = $(this).prop('selectedIndex');
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"move","value2":"' + number + '","value3":""}');
	});

	$("#am_prev_button").on('click', function(e) {
		e.preventDefault();
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"moveprev","value2":"","value3":""}');
	});
	$("#am_next_button").on('click', function(e) {
		e.preventDefault();
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"movenext","value2":"","value3":""}');
	});
	$("#am_store_button").on('click', function(e) {
		e.preventDefault();
		sendStringCommand('{"cmd":"updateconfig","param":"automovement","value":"store","value2":"","value3":""}');
	});
});

function amParseStatus(status) {

	var am_show_window = false;
	if (status.total_number > 0 || (status.state & 1) == 1) {
		am_show_window = true;
	}

	var loop_enabled = (status.state & 1) == 1;
	var shots_enabled = (status.state >> 1) & 1 == 1;
	var smooth_mode_enabled = (status.state >> 2) & 1 == 1;
	var smooth_speed_value = (status.state >> 5) & 7;

	$('#am_control_area').css('display', am_show_window ? 'block' : 'none');

	$('#am_current_field').html((status.current_number + 1) + '/' + status.total_number);	
	$('#am_nearest_field').html(status.nearest_number + 1);
	$('#am_speed_option').prop('selectedIndex', smooth_speed_value);

	$('#am_loop_enabled').prop('checked', loop_enabled);
	$('#am_photo_enabled').prop('checked', shots_enabled);
	$('#am_smooth_enabled').prop('checked', smooth_mode_enabled);

	var current_presets_options_count = $('#am_position_option option').length;
	if (current_presets_options_count != status.total_number) {
		$('#am_position_option').empty();
		for (var i = 0; i < status.total_number; i++) {
			$('#am_position_option').append($('<option>', {
		    	value: i,
		    	text: 'Position ' + (i+1)
			}));
		}
	}
	$('#am_position_option').prop('selectedIndex', status.current_number);
}


/*function BtGimbalReset() {
	sendStringCommand("!{\"cmd\":\"position\",\"param\":\"normal\"}");
}

function BtGimbalSetMode(mode) {
	sendStringCommand("!{\"cmd\":\"gimbal\",\"param\":\"mode\",\"value\":\"" + mode + "\"}");
}
*/