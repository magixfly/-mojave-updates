var mouseButtonDown = false;
var prev_menu_chapter = "Info";
var prev_touch_event;
var dbltapTimestamp = 0;
var secondaryStartpoint = {}
var secondaryMouseDown = false;

$(document).ready(function() {

	var player_mode = parseInt(Cookies.get('video_player_mode'));
	if (isNaN(player_mode)) player_mode = 1;
	$("#video_player_option").prop('selectedIndex', player_mode);

	ResizePlayer($(window).width(), $(window).height(), window.orientation);
	ResizeQR($(window).width(), $(window).height());

	$(window).resize(function() {
		ResizePlayer($(window).width(), $(window).height(), window.orientation);
		ResizeQR($(window).width(), $(window).height());
	});

	$(window).on("orientationchange", function() {
		ResizePlayer($(window).width(), $(window).height(), window.orientation);
	});


	$("#video_renderer_switch").on("click", function(e) {
		var state = $(this).prop('checked');
		Cookies.set('video_old_renderer', state ? '1' : '0', { expires: 365 });
		document.location.reload();
	});

	
	$('#license_block').on("click", function(e) { 
		ToggleDeviceSettingsWindow("License");
	});

	$('#udp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#srt_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtsp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp2_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#mpegts_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#v4l2_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#dvbt_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#ndi_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#ndihx_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#onboard_rec_area').on("click", function(e) { ToggleDeviceSettingsWindow("Recording"); });


	/*$('#menu_icon').mouseover(function () {
		$('#menu_icon').css("opacity","1");
	}).mouseout(function () {
		$('#menu_icon').css("opacity","0.5");
	});*/


	/// Main menu icon click
	$('#menu_icon').on("click", ToggleMainMenu);

	/// Close window icon click
	$('#close_icon').on("click", function(e) {
		if (isDeviceSettingsWindowOpened()) ToggleDeviceSettingsWindow("");
		if (isMediaPlayerWindowOpened()) ToggleMediaPlayerWindow("");
	});


	/// Box settings menu item
	$('.main_menu_item').on("click", function(e) { SelectMenuItem($(this)); });

	/*$('#video_canvas').on("touchstart", onTouchStart);
	$('#video_canvas').on("touchend", onTouchEnd);
	$('#video_canvas').on("touchmove", onTouchMove);
	$('#video_canvas').on("mousedown", onStartMove);
	$('#video_canvas').on("mouseup", onEndMove);
	$('#video_canvas').on("mouseleave", onEndMove);
	$('#video_canvas').on("mousemove", onMove);*/


	$('#video_container').on("touchstart", onTouchStart);
	$('#video_container').on("touchend", onTouchEnd);
	$('#video_container').on("touchmove", onTouchMove);
	$('#video_container').on("mousedown", onStartMove);
	$('#video_container').on("mouseup", onEndMove);
	$('#video_container').on("mouseleave", onEndMove);
	$('#video_container').on("mousemove", onMove);

	$('#video_element').on("touchstart", onTouchStart);
	$('#video_element').on("touchend", onTouchEnd);
	$('#video_element').on("touchmove", onTouchMove);
	$('#video_element').on("mousedown", onStartMove);
	$('#video_element').on("mouseup", onEndMove);
	$('#video_element').on("mouseleave", onEndMove);
	$('#video_element').on("mousemove", onMove);

	$('#remotevideov1').on("touchstart", onTouchStart);
	$('#remotevideov1').on("touchend", onTouchEnd);
	$('#remotevideov1').on("touchmove", onTouchMove);
	$('#remotevideov1').on("mousedown", onStartMove);
	$('#remotevideov1').on("mouseup", onEndMove);
	$('#remotevideov1').on("mouseleave", onEndMove);
	$('#remotevideov1').on("mousemove", onMove);

	$('#remotevideov2').on("touchstart", secondaryOnTouchStart);
	$('#remotevideov2').on("touchend", secondaryOnTouchEnd);
	$('#remotevideov2').on("touchmove", secondaryOnTouchMove);
	$('#remotevideov2').on("mousedown", secondaryOnStartMove);
	$('#remotevideov2').on("mouseup", secondaryOnEndMove);
	$('#remotevideov2').on("mouseleave", secondaryOnEndMove);
	$('#remotevideov2').on("mousemove", secondaryOnMove);

	$("#video_player_option").on("change", function(e) { 
		var state = parseInt($(this).prop('selectedIndex'));
		Cookies.set('video_player_mode', state, { expires: 365 });
		document.location.reload();
	});


    $("body").keydown(function (e) {
		if (event.repeat) return;
		if (isDeviceSettingsWindowOpened()) return;
        var keyCode = e.keyCode || e.which;
		if (onKey(keyCode, true)) e.preventDefault(); 
    });

    $("body").keyup(function (e) {
		if (event.repeat) return;
		if (isDeviceSettingsWindowOpened()) return;
        var keyCode = e.keyCode || e.which;
		if (onKey(keyCode, false)) e.preventDefault(); 
    });


	function onKey(keyCode, state) {
        //console.log('onKeyDown ' + keyCode + ' state ' + state);

		var ret = false;

		try {
			ret = CameraOnKey(keyCode, state);
		} catch (e) {}

		try {
			ret = WiralOnKey(keyCode, state);
		} catch (e) {}

		return ret;
	}


	function onTouchStart(event) {
		//event.preventDefault();

		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}

		prev_touch_event = event;

		var pos = GetWindowXY(event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
		//alert('start ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		mouseButtonDown = true;

		try { CameraMoveStart(pos); } catch (e) {}

		if (isMainMenuOpened()) ToggleMainMenu();
		SetGamepadSettingsWindowState(false);
	}

	function onTouchEnd(event) {
		//event.preventDefault();
		var pos = GetWindowXY(prev_touch_event.originalEvent.changedTouches[0].pageX, prev_touch_event.originalEvent.changedTouches[0].pageY);
		//alert('end ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		try { CameraMoveStop(pos); } catch (e) {}
		 
		mouseButtonDown = false;

		// check double tap
		CheckToggleFullscreen();
	}

	function onTouchMove(event) {
		//event.preventDefault();
		prev_touch_event = event;

		try { 
			var pos = GetWindowXY(prev_touch_event.originalEvent.changedTouches[0].pageX, prev_touch_event.originalEvent.changedTouches[0].pageY);
			CameraMove(pos);
		 } catch (e) {}
	}



	function onStartMove(event) {
		event.preventDefault();

		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}

		var pos = GetWindowXY(event.pageX, event.pageY);
		//alert('start ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		mouseButtonDown = true;

		try { CameraMoveStart(pos); } catch (e) {}

		if (isMainMenuOpened()) ToggleMainMenu();
		SetGamepadSettingsWindowState(false);
	}

	function onEndMove(event) {
		event.preventDefault();
		if (!mouseButtonDown) return;
		var pos = GetWindowXY(event.pageX, event.pageY);
		//alert('end ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		mouseButtonDown = false;

		try { CameraMoveStop(pos); } catch (e) {}

		// check double tap
		CheckToggleFullscreen();
	}

	function onMove(event) {
		event.preventDefault();
		if (!mouseButtonDown) return;

		try {
			var pos = GetWindowXY(event.pageX, event.pageY);
			CameraMove(pos);
		} catch (e) {}
	}


	function secondaryOnTouchStart(event) {
		event.preventDefault();
		secondaryMouseDown = true;
		secondaryStartpoint.x = event.originalEvent.touches[0].pageX;
	 	secondaryStartpoint.y = event.originalEvent.touches[0].pageY;
	}

	function secondaryOnTouchEnd(event) {
		event.preventDefault();
		secondaryMouseDown = false;
	}

	function secondaryOnTouchMove(event) {
		event.preventDefault();
		if (!secondaryMouseDown) return;
		MoveSecondaryWindow($(this), event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
	}

	function secondaryOnStartMove(event) {
		event.preventDefault();
		secondaryMouseDown = true;
		secondaryStartpoint.x = event.pageX;
	 	secondaryStartpoint.y = event.pageY;
	}

	function secondaryOnEndMove(event) {
		event.preventDefault();
		secondaryMouseDown = false;
	}

	function secondaryOnMove(event) {
		event.preventDefault();
		if (!secondaryMouseDown) return;
		MoveSecondaryWindow($(this), event.pageX, event.pageY);
	}

	ShowHelloMessage();

	$("#mediaplayer_area").load("tpl/mediaplayer.tpl.html?" + Math.random());
});


function MoveSecondaryWindow(obj, x, y) {
	try {
		var old_x = parseInt(obj.css("left"));
		var old_y = parseInt(obj.css("top"));
		obj.css("left", old_x + (x - secondaryStartpoint.x));
		obj.css("top", old_y + (y - secondaryStartpoint.y));
	} catch (e) { console.log(e); }

	secondaryStartpoint.x = x;
	secondaryStartpoint.y = y;
}


function GetWindowXY(x, y) {

	var windowWidth = parseInt($('#video_canvas').css('width'));
	var windowHeight = parseInt($('#video_canvas').css('height'));
	var offsetX = parseInt($('#video_container').css('margin-left'));
	var offsetY = parseInt($('#video_container').css('margin-top')) + parseInt($('#top_area').css('height')) + 10;
	var new_x = parseInt(x - offsetX);
	var new_y = parseInt(y - offsetY);
	if (new_x < 0) new_x = 0;
	if (new_y < 0) new_y = 0;

	var pers_x = new_x / windowWidth;
	var pers_y = new_y / windowHeight;
	if (pers_x < 0) pers_x = 0;
	if (pers_x > 1) pers_x = 1;
	if (pers_y < 0) pers_y = 0;
	if (pers_y > 1) pers_y = 1;

	var res = {
		x: new_x,
		y: new_y,
		pers_x: pers_x,
		pers_y: pers_y
	}

	return res;
}


function CheckToggleFullscreen() {
	var timestamp = new Date().getTime();
	var delta = timestamp - dbltapTimestamp;
	dbltapTimestamp = timestamp;
	if ((delta > 50) && (delta <= 200)) {
		ToggleFullscreen();
		return;
	}
}

function ToggleFullscreen() {

	/// If already full screen else go fullscreen
	if (
		document.fullscreenElement ||
		document.webkitFullscreenElement ||
		document.mozFullScreenElement ||
		document.msFullscreenElement
	) {
		if (document.exitFullscreen) {
			document.exitFullscreen();
		} else if (document.mozCancelFullScreen) {
			document.mozCancelFullScreen();
		} else if (document.webkitExitFullscreen) {
			document.webkitExitFullscreen();
		} else if (document.msExitFullscreen) {
			document.msExitFullscreen();
		}

		//if (is_settings_opened()) toggle_settings_window();
		//$(".fw_hide").css("display","block");

	} else {
		element = $('body').get(0);

		if (element.requestFullscreen) {
			element.requestFullscreen();
		} else if (element.mozRequestFullScreen) {
			element.mozRequestFullScreen();
		} else if (element.webkitRequestFullscreen) {
			element.webkitRequestFullscreen(Element.ALLOW_KEYBOARD_INPUT);
		} else if (element.msRequestFullscreen) {
			element.msRequestFullscreen();
		}

		//if (is_settings_opened()) toggle_settings_window();
		//$(".fw_hide").css("display","none");
	}

	$("body").css("width","100%");

	ShowHelloMessage();
}

function ShowHelloMessage() {
	$("#hellomessage").css("display", "block");
	setTimeout(function(){$("#hellomessage").fadeOut(1000);}, 1000);
}


function ResizePlayer(width, height, orientation) {
	var top_height = parseInt($("#top_area").css("height"));
	var btm_height = parseInt($("#bottom_area").css("height"));
	if (top_height == 0) top_height = 16;
	if (btm_height == 0) btm_height = 16;

	//$("#top_area").html(top_height + " " + btm_height);

	var real_height = height - top_height - btm_height - 5*4; // 4 paddings of 5 pixels

	var new_width = width;
	var new_height = width / 16 * 9;

	if (new_height > real_height) {
		new_height = real_height;
		//new_width = real_height / 9 * 16;
	}

	$("#video_container").css("width", new_width);
	$("#video_container").css("height", new_height);

	$("#video_container").css("margin-top", (real_height - new_height) / 2);
	$("#video_container").css("margin-left", (width - new_width) / 2);

	//$("#left_area").css("margin-top", height / 2 - parseInt($("#left_area").css('height'))/2);
	$("#left_area").css("height", parseInt($("#video_container").css("height")) - 40);	

	//$("#right_area").css("margin-top", parseInt($("#video_container").css("margin-top")));
	//$("#right_area").css("height", parseInt($("#video_container").css("height")) - 16);	

	$("#video_canvas").css("width", new_width);
	$("#video_canvas").css("height", new_height);

	$("#remotevideov1").css("width", new_width);
	$("#remotevideov1").css("height", new_height);
}


function ResizeQR(width, height) {
	var min_width = width - width / 10;
	var min_height = height - height / 3;

	var new_height = min_height;
	if (new_height > min_width) new_height = min_width;

	$("#qr_image").css("height", new_height);
}


function ToggleMainMenu() {

	if ($("#menu_main").css("display") != "block") {
		$("#menu_main").css("display", "block");
	} 
	else {
		$("#menu_main").css("display", "none");
	}
}


function isMainMenuOpened() {
	return $("#menu_main").css("display") == "block";
}


function SelectMenuItem(item) {
	switch ($(item).attr("id")) {

		/// Box settings
		case "menu_main_item1":
			if (!isConnected()) return;
			ToggleDeviceSettingsWindow("");
		break;

		/// Camera settings
		case "menu_main_item2":
			if (!isCameraConnected()) return;
			try { CameraSettingsToggle(); } catch (e) {}
		break;

		/// Camera controls
		case "menu_main_item5":
			if (!isCameraConnected()) return;
			try { CameraControlsToggle(); } catch (e) {}
		break;

		/// Console
		case "menu_main_item3":
			window.open('/console', '_blank');
		break;

		/// File manager
		case "menu_main_item4":
			window.open('/files', '_blank');
		break;

		/// USB Storage
		case "menu_main_item6":
			window.open('/files/index.php?p=media%2Fusb', '_blank');
		break;

		/// MicroSD Storage
		case "menu_main_item7":
			window.open('/files/index.php?p=mnt', '_blank');
		break;

		/// DJI FPV Goggles Storage
		case "menu_main_item8":
			window.open('/files/index.php?p=tmp%2Fdjifpvgoggles-storage', '_blank');
		break;

		/// Media player
		case "menu_main_item9":
			if (!isConnected()) return;
			ToggleMediaPlayerWindow("");
		break;

		/// Gamepad settings
		case "menu_main_item10":
			ToggleGamepadSettingsWindow();
		break;
	}

	if (isMainMenuOpened()) ToggleMainMenu();
}


function ToggleDeviceSettingsWindow(chapter) {
	if ($("#devicesettings_area").css("display") != "block") {
		$("#devicesettings_area").load("tpl/devicesettings.tpl.html?" + Math.random());
		$("#devicesettings_area").css("display","block");
		if (chapter != "") prev_menu_chapter = chapter;
		$("#close_icon").css("display","inline");
		$("#menu_icon").css("display","none");
	} else {
		$("#devicesettings_area").css("display","none");
		$("#close_icon").css("display","none");
		$("#menu_icon").css("display","inline");
	}
}

function isDeviceSettingsWindowOpened() {
	return $("#devicesettings_area").css("display") == "block" ? true : false;
}



function ToggleMediaPlayerWindow(chapter) {
	if ($("#mediaplayer_area").css("display") != "block") {

		$("#mediaplayer_area").css("display","block");
		$("#close_icon").css("display","block");
		$("#menu_icon").css("display","none");

		MP_Update();

	} else {
		$("#mediaplayer_area").css("display","none");
		$("#close_icon").css("display","none");
		$("#menu_icon").css("display","block");
	}
}

function isMediaPlayerWindowOpened() {
	return $("#mediaplayer_area").css("display") == "block" ? true : false;
}
