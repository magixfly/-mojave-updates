var mouseButtonDown = false;
var menu_chapter = "Info";
var prev_menu_chapter = "Info";
var prev_touch_event;
var dbltapTimestamp = 0;
var secondaryStartpoint = {}
var secondaryMouseDown = false;
var touch_start_timestamp = 0;

$(document).ready(function() {

	/*document.oncontextmenu = function() {
  		return false;
	}*/

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

	$('#enable_screen_capture_button').on("click", function(e) { 
		var cmd = '{"cmd":"updateconfig","param":"transcoding","value":"1","value2":"2000000","value3":"1","value4":"1280","value5":"720","value6":"","value7":"","value8":"0"}';
		sendStringCommand(cmd);
	});

	$('#switch_h264_button').on("click", function(e) { 
		sendStringCommand('!{"cmd":"stream","param":"codec","value":"h264"}');
	});

	$('#transcoding_type0').on("click", function(e) { ToggleDeviceSettingsWindow("Video/Audio"); });
	$('#transcoding_type1').on("click", function(e) { ToggleDeviceSettingsWindow("Video/Audio"); });

	$('#udp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#srt_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtsp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp2_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_youtube_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_instagram_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_facebook_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_tiktok_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
	$('#rtmp_telegram_restream_area').on("click", function(e) { ToggleDeviceSettingsWindow("Streaming"); });
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

	$('#bglayer').on("touchstart", function(event) {
	});
	$('#bglayer').on("touchend", function(event) {
		ShowMainMenu(false);
		SetGamepadSettingsWindowState(false);
		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}
	});
	$('#bglayer').on("mousedown", function(event) {
	});
	$('#bglayer').on("mouseup", function(event) {
		ShowMainMenu(false);
		SetGamepadSettingsWindowState(false);
		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}
	});


	/// Main menu icon click
	$('#menu_icon').on("click", function(event) {
		event.preventDefault();
		ToggleMainMenu();
	});

	/// Close window icon click
	$('#close_icon').on("click", function(e) {
		if (isDeviceSettingsWindowOpened()) ToggleDeviceSettingsWindow("");
		if (isMediaPlayerWindowOpened()) ToggleMediaPlayerWindow("");
	});

	/// Box settings menu item
	$('.main_menu_item').on("click", function(e) { SelectMenuItem($(this)); });

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

	/// For IOS fullscreen
	const v = document.getElementById("remotevideov1");

	$('#video_play_button').on('click', function() {
		v.play();
		HideVideoResumeButton();
	});

	function ShowVideoResumeButton() {
    	$("#video_play_request_container").addClass("show");
	}

	function HideVideoResumeButton() {
    	$("#video_play_request_container").removeClass("show");
	}

	function resumeVideo() {
		/// If video paused - restart
		if (v.paused) {
			const p = v.play();
			if (p && typeof p.catch === "function") {
				ShowVideoResumeButton();
			}
		}
	}

	/// iPhone Safari: exit from fullscreen for <video>
	v.addEventListener("webkitendfullscreen", () => {
	/// Very importand: wait a little!
		setTimeout(resumeVideo, 100);
	});

	/// Sometimes happens
	v.addEventListener("webkitfullscreenchange", () => {
		/// If not in a fullscreen
		if (!v.webkitDisplayingFullscreen) {
			setTimeout(resumeVideo, 100);
		}
	});

	/// Fallback for a standard Fullscreen API
	document.addEventListener("fullscreenchange", () => {
		if (!document.fullscreenElement) {
			setTimeout(resumeVideo, 100);
		}
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

		/// Skip double events
		var timestamp = new Date().getTime();
		var dt = timestamp - touch_start_timestamp;
		if (dt < 100) return;
		touch_start_timestamp = timestamp;

		var pos = GetWindowXY(event.originalEvent.touches[0].pageX, event.originalEvent.touches[0].pageY);
		//console.log('start ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		/// Click on the right side of video window
		if (pos.pers_x >= 0.9) {
			try { CameraControlsToggle(); } catch (e) {}
			return;
		}

		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}

		prev_touch_event = event;

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

		/// Skip double events
		var timestamp = new Date().getTime();
		var dt = timestamp - touch_start_timestamp;
		if (dt < 100) return;
		touch_start_timestamp = timestamp;

		var pos = GetWindowXY(event.pageX, event.pageY);
		//console.log('start ' + pos.x + ' ' + pos.y + ' ' + pos.pers_x + ' ' + pos.pers_y);

		/// Click on the right side of video window
		if (pos.pers_x >= 0.9) {
			try { CameraControlsToggle(); } catch (e) {}
			return;
		}

		try { if ($("#camera_settings").css("display") != "none") CameraSettingsToggle(); } catch (e) {}
		try { if ($("#camera_controls").css("display") != "none") CameraControlsToggle(); } catch (e) {}

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

	if (!supportsElementFullscreen()) {
		//alert('Fullscreen is not supported');
		/// For IOS
		const v = document.getElementById('remotevideov1');
		v.play();
		if (v.webkitEnterFullscreen) {
      		v.webkitEnterFullscreen();
			return;
    	}
	}

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

		else {
			//const v = document.getElementById('remotevideov1');
			//v.webkitEnterFullscreen();
		}

		//if (is_settings_opened()) toggle_settings_window();
		//$(".fw_hide").css("display","none");
	}

	$("body").css("width","100%");

	ShowHelloMessage();
}

function supportsElementFullscreen() {
  return !!(
    document.fullscreenEnabled ||
    document.webkitFullscreenEnabled
  );
}

function ShowHelloMessage() {
	$("#hellomessage").css("display", "block");
	setTimeout(function(){$("#hellomessage").fadeOut(1000);}, 1000);
}

function ShowBtStatus(text) {
	$("#bt_status_message").html(text);
	$("#bt_status_message").css('display', text.length == 0 ? "none" : "block");
	setTimeout(function(){$("#bt_status_message").fadeOut(1000);}, 3000);
}

function ResizePlayer(width, height, orientation) {
	var top_height = parseInt($("#top_area").css("height"));
	var btm_height = parseInt($("#bottom_area").css("height"));
	if (top_height == 0) top_height = 16;
	if (btm_height == 0) btm_height = 16;

	//$("#top_area").html(top_height + " " + btm_height);

	//var real_height = height - top_height - btm_height - 5*4; // 4 paddings of 5 pixels
	var real_height = height - top_height - btm_height - 5*4; // 4 paddings of 5 pixels

	var new_width = width;
	var new_height = width / 16 * 9 + 4;

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
	$("#remotevideov1").css("height", new_height + 4);
}


function ResizeQR(width, height) {
	var min_width = width - width / 10;
	var min_height = height - height / 3;

	var new_height = min_height;
	if (new_height > min_width) new_height = min_width;

	$("#qr_image").css("height", new_height);
}

function ShowMainMenu(state) {
	$("#menu_main").css("display", state? "block" : "none");
}

function ToggleMainMenu() {
	if (isMainMenuOpened()) {
		ShowMainMenu(false);
	} 
	else {
		ShowMainMenu(true);
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

	/// Call clear function
	try {
		DeinitDeviceSettings();
	} catch (e) {}
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


function ShowConnectionArea(state) {
	if (state) {
		$('#connection-container').delay(0).fadeIn(500);
	} else {
		$('#connection-container').delay(0).fadeOut(500);
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

function ShowVideoError(text) {
	if (text != '') {
		$("#videoerror_block").css('display', 'block');
		$("#videoerror_block").html('Video: ' + text);

		$("#remotevideov2").css('display', 'none');
	} else {
		$("#videoerror_block").css('display', 'none');
		$("#videoerror_block").html(text);
	}
}

function showButtonClicked(el, color1, color2) {
	$(el).css('background-color', color1);
	setTimeout(function() {
		$(el).css('background-color', color2);
	}, 2000);
}

function reload_page() {
	window.location.reload();
}

function setCookie(name,value,days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days*24*60*60*1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}

function getCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}

function eraseCookie(name) {   
    document.cookie = name +'=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
}
