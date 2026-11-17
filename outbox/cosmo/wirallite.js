var wiralCheckInterval = null;
var wiralWindowStartpoint = {}
var wiralWindowMouseDown = false;

var wiralStatus = {
	timestamp: 0,
	remote_connected: false,
	mainunit_connected: false,
	startpoint_ready: false,
	endpoint_ready: false,
	current_distance: 0,
	max_distance: 0,
	current_speed: 0,
	max_speed: 0,
	default_speed: 0,
	tictac: false,
	tictac_speed: 0,
	tictac_next_distance: 0,
	tictac_counter: 0,
	tictac_tic_time: 0,
	tictac_prev_tic_time: 0
}

$(document).ready(function() {

	$('#wiral_control_header').on("touchstart", wiralWindowOnTouchStart);
	$('#wiral_control_header').on("touchend", wiralWindowOnTouchEnd);
	$('#wiral_control_header').on("touchmove", wiralWindowOnTouchMove);
	$('#wiral_control_header').on("mousedown", wiralWindowOnStartMove);
	$('#wiral_control_header').on("mouseup", wiralWindowOnEndMove);
	$('#wiral_control_header').on("mouseleave", wiralWindowOnEndMove);
	$('#wiral_control_header').on("mousemove", wiralWindowOnMove);

	function wiralWindowOnTouchStart(event) {
		event.preventDefault();
		wiralWindowMouseDown = true;
		wiralWindowStartpoint.x = event.originalEvent.touches[0].pageX;
	 	wiralWindowStartpoint.y = event.originalEvent.touches[0].pageY;
	}

	function wiralWindowOnTouchEnd(event) {
		event.preventDefault();
		wiralWindowMouseDown = false;
	}

	function wiralWindowOnTouchMove(event) {
		event.preventDefault();
		if (!wiralWindowMouseDown) return;
		MoveWiralWindow($(this), event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
	}

	function wiralWindowOnStartMove(event) {
		event.preventDefault();
		wiralWindowMouseDown = true;
		wiralWindowStartpoint.x = event.pageX;
	 	wiralWindowStartpoint.y = event.pageY;
	}

	function wiralWindowOnEndMove(event) {
		event.preventDefault();
		wiralWindowMouseDown = false;
	}

	function wiralWindowOnMove(event) {
		event.preventDefault();
		if (!wiralWindowMouseDown) return;
		MoveWiralWindow($(this), event.pageX, event.pageY);
	}

	function MoveWiralWindow(obj, x, y) {
		try {
			var obj = $("#wiral_control_area");
			var old_x = parseInt(obj.css("left"));
			var old_y = parseInt(obj.css("top"));
			obj.css("left", old_x + (x - wiralWindowStartpoint.x));
			obj.css("top", old_y + (y - wiralWindowStartpoint.y));
		} catch (e) { console.log(e); }

		wiralWindowStartpoint.x = x;
		wiralWindowStartpoint.y = y;
	}


	$('#wiral_set_speed_slider').on("mousemove touchmove mouseup touchend", function(e) {
		var maxspeed = parseInt(wiralStatus.max_speed);
		var this_speed = parseInt($(this).val());
		var defspeed = parseInt(this_speed * (maxspeed / 255));
		$("#wiral_set_speed_text").html(defspeed);

		if (wiralStatus.tictac) SetTicTacMode(true, defspeed);
	});

	$('#wiral_set_position_slider_main').on("mousemove touchmove", function(e) {
		var maxspeed = parseInt(wiralStatus.max_speed);
		var this_speed = parseInt($('#wiral_set_speed_slider').val());
		var speed = parseInt(this_speed * (maxspeed / 255));
		var position = parseInt((parseInt($(this).val()) / 100.0) * wiralStatus.max_distance);
		$("#wiral_current_destination_text").html(position);
	});	

	$('#wiral_set_position_slider_main').on("mouseup touchend", function(e) {
		var maxspeed = parseInt(wiralStatus.max_speed);
		var this_speed = parseInt($('#wiral_set_speed_slider').val());
		var speed = parseInt(this_speed * (maxspeed / 255));
		var position = parseInt((parseInt($(this).val()) / 100.0) * wiralStatus.max_distance);
		$("#wiral_current_destination_text").html(position);
		try { WiralMove(position, speed); } catch (e) {}
	});

	$('#wiral_tictac_enabled').on('change', function(e) {
		var state = $(this).prop('checked');
		var speed = parseInt(parseInt($('#wiral_set_speed_slider').val()) * (parseInt(wiralStatus.max_speed) / 255));
		SetTicTacMode(state, speed);
	});


	$('#wiral_move_back').on('mousedown touchstart', function(e) {
		e.preventDefault();
		var speed = parseInt(parseInt($('#wiral_set_speed_slider').val()) * (parseInt(wiralStatus.max_speed) / 255));
		WiralMove(0, speed);
	});

	$('#wiral_move_back').on('mouseup touchend', function(e) {
		e.preventDefault();
		WiralMove(0, 0);
	});

	$('#wiral_move_forward').on('mousedown touchstart', function(e) {
		e.preventDefault();
		var speed = parseInt(parseInt($('#wiral_set_speed_slider').val()) * (parseInt(wiralStatus.max_speed) / 255));
		WiralMove(65535, speed);
	});

	$('#wiral_move_forward').on('mouseup touchend', function(e) {
		e.preventDefault();
		WiralMove(0, 0);
	});

	$('#wiral_stop').on('mousedown touchstart', function(e) {
		e.preventDefault();
		WiralMove(0, 0);
	});

	$('#wiral_stop').on('mouseup touchend', function(e) {
		e.preventDefault();
		WiralMove(0, 0);
	});

});

function WiralParseStatus(data) {
	if (data.Length < 25) return;
	//console.log(data);

	if (wiralCheckInterval == null) {
		wiralCheckInterval = setInterval(WiralCheck, 1000);
	}

	var needInit = false;
	if (!wiralStatus.remote_connected) {
		needInit = true;
		onWiralFound();
	}

	wiralStatus.timestamp = new Date().getTime();
	wiralStatus.remote_connected = true;

	wiralStatus.mainunit_connected = data[1] == 1;
	wiralStatus.startpoint_ready = data[2] == 1;
	wiralStatus.endpoint_ready = data[3] == 1;
	wiralStatus.current_distance = data[4] + (data[5] << 8);
	wiralStatus.max_distance = data[6] + (data[7] << 8);
	wiralStatus.current_speed = Int16(data[8] + (data[9] << 8));
	wiralStatus.max_speed = data[10];
	wiralStatus.default_speed = data[11];

	wiralStatus.tictac = data[12] == 1;
	wiralStatus.tictac_speed = data[13];
	wiralStatus.tictac_next_distance = data[14] + (data[15] << 8);
	wiralStatus.tictac_counter = data[16] + (data[17] << 8);
	wiralStatus.tictac_tic_time = data[18] + (data[19] << 8) + (data[20] << 16) + (data[21] << 24);
	wiralStatus.tictac_prev_tic_time = data[22] + (data[23] << 8) + (data[24] << 16) + (data[25] << 24);

	try { wiralStatus.battery_level = data[26]; } catch (e) { wiralStatus.battery_level = 0; }

	//console.log(wiralStatus);

	$('#wiral_current_destination_text').html();
	$('#wiral_current_position_text').html(wiralStatus.current_distance);
	$('#wiral_current_speed_text').html(wiralStatus.current_speed);
	$('#wiral_current_position_slider').val((parseInt(wiralStatus.current_distance) / parseInt(wiralStatus.max_distance)) * 100);
	$('#wiral_tictac_enabled').prop('checked', wiralStatus.tictac ? 'checked' : '');

	$('#wiral_battery_level_text').html(wiralStatus.battery_level + '%');

	if (wiralStatus.tictac) {
		$('#wiral_tictac_times').css('display', 'inline');
		$('#wiral_tic_time').html(makeTimerStringMs(wiralStatus.tictac_tic_time));
		$('#wiral_prev_tic_time').html(makeTimerStringMs(wiralStatus.tictac_prev_tic_time));
	} else {
		$('#wiral_tictac_times').css('display', 'none');
	}

	$('#wiral_start_point_label').css('display', wiralStatus.startpoint_ready ? 'none' : 'inline');
	$('#wiral_end_point_label').css('display', wiralStatus.endpoint_ready ? 'none' : 'inline');


	if (needInit) {
		$('#wiral_set_speed_slider').val(parseInt(wiralStatus.default_speed) / parseInt(wiralStatus.max_speed) * 255);
		$('#wiral_set_speed_text').html(parseInt(wiralStatus.default_speed));
	}

	var status_str = 'Remote not connected';
	if (wiralStatus.remote_connected && !wiralStatus.mainunit_connected) status_str = 'Main unit not connected';
	if (wiralStatus.remote_connected && wiralStatus.mainunit_connected) status_str = 'Main unit connected';

	if (wiralStatus.remote_connected && wiralStatus.mainunit_connected) {
		if ($('#wiral_control_area_full').css('display') != 'block') $('#wiral_control_area_full').css('display', 'block');
		if ($('#wiral_control_area_nc').css('display') != 'none') $('#wiral_control_area_nc').css('display', 'none');
	} else {
		if ($('#wiral_control_area_full').css('display') != 'none') $('#wiral_control_area_full').css('display', 'none');
		if ($('#wiral_control_area_nc').css('display') != 'block') $('#wiral_control_area_nc').css('display', 'block');
		$('#wiral_control_area_nc_message').html(status_str);
	}


	try { if (HookWiralParse != undefined) HookWiralParse(wiralStatus); } catch (e) {}
}


function onWiralFound() {
	console.log('Wiral Lite found');

	$('#wiral_control_area').css('display', 'block');

	try { if (HookWiralFound != undefined) HookWiralFound(); } catch (e) {}
}


function onWiralLost() {
	console.log('Wiral Lite lost');

	$('#wiral_control_area').css('display', 'none');

	try { if (HookWiralLost != undefined) HookWiralLost(); } catch (e) {}
}


function WiralCheck() {
	if (wiralStatus.timestamp > 0) {
		var dt = new Date().getTime() - wiralStatus.timestamp;
		if (dt > 3000) {
			wiralStatus.timestamp = 0;
			wiralStatus.remote_connected = 0;
			onWiralLost();
		}
	}
}


function WiralOnKey(keyCode, state) {
	var speed = 0;
	switch (keyCode) {
		case 78:
			if (state) speed = parseInt(parseInt($('#wiral_set_speed_slider').val()) * (parseInt(wiralStatus.max_speed) / 255));			
			WiralMove(0, speed);
			return true;
		break;

		case 77:
			if (state) speed = parseInt(parseInt($('#wiral_set_speed_slider').val()) * (parseInt(wiralStatus.max_speed) / 255));
			WiralMove(65535, speed);
			return true;
		break;
	}

	return false;
}


function WiralMove(position, speed) {
	/// 20 - binary cmd type
	/// 1 - set new position and speed
	sendStringCommand('!{"cmd":"wiral","param":"position","value":"set","value2":"' + position + '","value3":"' + speed + '"}');
}


function SetTicTacMode(state, speed) {
	/// 20 - binary cmd type
	/// 2 - set tic tac mode with speed
	sendStringCommand('!{"cmd":"wiral","param":"mode","value":"tic-tac","value2":"' + (state ? 1 : 0) + '","value3":"' + speed + '"}');
}
