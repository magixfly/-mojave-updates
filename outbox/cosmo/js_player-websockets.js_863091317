var player_jmuxer_params = {
	ws_video: null,
	ws_video_connected: false,
	jmuxer: null,
	current_host: null,
	video_interval: null,
	connecting: false,
	currentTime: 0  
}

$(document).ready(function() {

	var player_mode = parseInt(Cookies.get('video_player_mode'));
	if (isNaN(player_mode)) player_mode = 1;
	if (player_mode != 0) return;

	try {
		if (document.location.host != "") PlayerJmuxerStart(document.location.host);
	} catch {}
});

function PlayerJmuxerStart(host) {
	if (host == "") return;
	if (host == null) return;
	if (host == undefined) return;

	player_jmuxer_params.current_host = host;
	if (player_jmuxer_params.video_interval != null) clearInterval(player_jmuxer_params.video_interval);
	player_jmuxer_params.video_interval = setInterval(PlayerJmuxerRun, 1000);
	PlayerJmuxerRun();
}

function PlayerJmuxerRun() {
	//var useOldVideoRenderer = Cookies.get('video_old_renderer') == 1 ? 1 : 0;

	if (player_jmuxer_params.ws_video_connected) {
		return;
	}

	if (player_jmuxer_params.connecting) {
		console.log('already connecting');
		return;
	}

	player_jmuxer_params.connecting = true;

	if (player_jmuxer_params.jmuxer != null) {
		player_jmuxer_params.jmuxer = null;
	}

	if (player_jmuxer_params.ws_video != null) {
		try { if (!player_jmuxer_params.ws_video.connected) player_jmuxer_params.ws_video.close(); } catch (ex) { }
		player_jmuxer_params.ws_video = null;
	}

	var uri = "ws://" + player_jmuxer_params.current_host + ":8080";

	try {
		var framerate = 30;

		/// For DJI FPV Goggles fps 60
		if (global_app_type == 17) framerate = 60;

	    player_jmuxer_params.jmuxer = new JMuxer({
			node: 'video_element',
			mode: 'video',
			flushingTime: 10,
			fps: framerate,
			debug: false,
			onError: function(data) {
				player_jmuxer_params.jmuxer.reset();
			}
		});

		player_jmuxer_params.ws_video = new WebSocket(uri);
		player_jmuxer_params.ws_video.binaryType = 'arraybuffer';

		player_jmuxer_params.ws_video.addEventListener('message',function(event) {
			player_jmuxer_params.jmuxer.feed({
				video: new Uint8Array(event.data)
			});
		});

		player_jmuxer_params.ws_video.addEventListener('error', function(e) {
			PlayerJmuxerOnVideoDisconnected();
		});

		player_jmuxer_params.ws_video.addEventListener('close', function(e) {
			PlayerJmuxerOnVideoDisconnected();
		});

		player_jmuxer_params.ws_video.addEventListener('open', function(e) {
			PlayerJmuxerOnVideoConnected();
		});


		/*document.querySelector('#video_element').addEventListener('timeupdate',  evt => {
			var video = document.querySelector('#video_element');
			player_jmuxer_params.currentTime = video.currentTime;
			//console.log("timeupdate " + video.currentTime);
		});

		document.querySelector('#video_element').addEventListener('play',  evt => { 
			console.log('playback started');
		});

		document.querySelector('#video_element').addEventListener('pause',  evt => { 
			console.log('playback paused');

			var video = document.querySelector('#video_element');
   		    video.currentTime = player_jmuxer_params.currentTime - 0.01;
	        video.play();
		});*/

	} catch (e) { 
		//alert(e);
	}
}

function PlayerJmuxerOnVideoConnected() {
	player_jmuxer_params.ws_video_connected = true;
	player_jmuxer_params.connecting = false;

	//$("body").css('background-image','none');
	$("#video_container").css("display", "block");
	$("#video_element").css("display", "block");
}

function PlayerJmuxerOnVideoDisconnected() {

	try { player_jmuxer_params.ws_video.close(); } catch (e) {}

	player_jmuxer_params.ws_video = null;
	player_jmuxer_params.ws_video_connected = false;
	player_jmuxer_params.connecting = false;

	//$("body").css('background-image','block');
	$("#video_element").css("display", "none");
}
