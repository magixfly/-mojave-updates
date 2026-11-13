var player_janus_params = {
	janus: null,
	streaming: null,
	opaqueId: "streamingtest-"+Janus.randomString(12),
	bitrateTimer: {},
	streamsList: {},
	remoteTracks: {},
	selectedStream: null,
	server: "http://" + window.location.hostname + ":8088/janus",
	iceServers: null,
	show_main_cam: false
}

$(document).ready(function() {

	var player_mode = parseInt(Cookies.get('video_player_mode'));
	if (isNaN(player_mode)) player_mode = 1;
	if (player_mode == 1) player_janus_params.show_main_cam = true;

	/// Very dirty hack until i found how to detect client connections to mid v2 
	if (player_janus_params.show_main_cam) {
		sendStringCommand('webrtc-main-camera');
		setInterval(function() {
			sendStringCommand('webrtc-main-camera');
		}, 1000);
	}

	janus_init();

	$("#audio_on_icon").on("click", function(e) {
		$('#remotevideoa').get(0).pause();
		$('#remotevideoa').get(0).volume = 1;
		//$("#audio_off_icon").css('display', 'inline');
		//$("#audio_on_icon").css('display', 'none');
	});
	$("#audio_off_icon").on("click", function(e) {
		$('#remotevideoa').get(0).play();
		$('#remotevideoa').get(0).volume = 1;
		//$("#audio_off_icon").css('display', 'none');
		//$("#audio_on_icon").css('display', 'inline');
	});

	setInterval(function() {
		var audioState = $('#remotevideoa').get(0).paused;
		if (audioState) {
			if ($("#audio_off_icon").css('display') != 'inline') $("#audio_off_icon").css('display', 'inline');
			if ($("#audio_on_icon").css('display') != 'none') $("#audio_on_icon").css('display', 'none');
		} else {
			if ($("#audio_off_icon").css('display') != 'none') $("#audio_off_icon").css('display', 'none');
			if ($("#audio_on_icon").css('display') != 'inline') $("#audio_on_icon").css('display', 'inline');
		}
	}, 1000);

});

function PlayerWebrtcPlay() {
	PlayerWebrtcStartStream(1);
}

function janus_init() {

	// Initialize the library (all console debuggers enabled)
	//Janus.init({debug: "all", callback: function() {
	Janus.init({callback: function() {

			// Make sure the browser supports WebRTC
			if(!Janus.isWebrtcSupported()) {
				alert("No WebRTC support... ");
				return;
			}

			// Create session
			player_janus_params.janus = new Janus(
				{
					server: player_janus_params.server,
					iceServers: player_janus_params.iceServers,

					success: function() {

						// Attach to Streaming plugin
						player_janus_params.janus.attach(
							{
								plugin: "janus.plugin.streaming",
								opaqueId: player_janus_params.opaqueId,
								success: function(pluginHandle) {

									player_janus_params.streaming = pluginHandle;
									Janus.log("Plugin attached! (" + player_janus_params.streaming.getPlugin() + ", id=" + player_janus_params.streaming.getId() + ")");

									// Setup streaming session
									updateStreamsList();

								},

								error: function(error) {
									Janus.error("  -- Error attaching plugin... ", error);
									alert("Error attaching plugin... " + error);
								},

								iceState: function(state) {
									Janus.log("ICE state changed to " + state);
								},

								webrtcState: function(on) {
									Janus.log("Janus says our WebRTC PeerConnection is " + (on ? "up" : "down") + " now");
								},

								slowLink: function(uplink, lost, mid) {
									Janus.warn("Janus reports problems " + (uplink ? "sending" : "receiving") +
										" packets on mid " + mid + " (" + lost + " lost packets)");
								},

								onmessage: function(msg, jsep) {
									console.log(" ::: Got a message :::", msg);
									var result = msg["result"];
									if(result) {
										if(result["status"]) {
											var status = result["status"];
											if(status === 'starting') {
											} else if(status === 'started') {
											} else if(status === 'stopped')
												stopStream();
										} else if(msg["streaming"] === "event") {
										}
									} else if(msg["error"]) {
										console.log('error: ', msg["error"]);
										stopStream();
										return;
									}

									if(jsep) {
										Janus.debug("Handling SDP as well...", jsep);
										var stereo = (jsep.sdp.indexOf("stereo=1") !== -1);

										// Offer from the plugin, let's answer
										player_janus_params.streaming.createAnswer(
											{
												jsep: jsep,
												// We only specify data channels here, as this way in
												// case they were offered we'll enable them. Since we
												// don't mention audio or video tracks, we autoaccept them
												// as recvonly (since we won't capture anything ourselves)
												tracks: [
													{ type: 'data' }
												],

												customizeSdp: function(jsep) {
													if(stereo && jsep.sdp.indexOf("stereo=1") == -1) {
														// Make sure that our offer contains stereo too
														jsep.sdp = jsep.sdp.replace("useinbandfec=1", "useinbandfec=1;stereo=1");
													}
												},

												success: function(jsep) {
													Janus.debug("Got SDP!", jsep);
													var body = { request: "start" };
													player_janus_params.streaming.send({ message: body, jsep: jsep });
												},

												error: function(error) {
													Janus.error("WebRTC error:", error);
													alert("WebRTC error... " + error.message);
												}
											});
									}
								},

								onremotetrack: function(track, mid, on) {

									/// Don't show main camera if needed
									if (!player_janus_params.show_main_cam) {
										if (mid == "v1") return;
									}

									Janus.debug("Remote track (mid=" + mid + ") " + (on ? "added" : "removed") + ":", track);

									var mstreamId = "mstream"+mid;
									if (player_janus_params.streamsList[player_janus_params.selectedStream] && player_janus_params.streamsList[player_janus_params.selectedStream].legacy) mstreamId = "mstream0";

									if(!on) {
										// Track removed, get rid of the stream and the rendering
										$('#remotevideo' + mid).css('display', 'none');
										//$('#audio_icons_area').css('display', 'none');

										var stream = player_janus_params.remoteTracks[mid];
										if(stream) {
											try {
												var tracks = stream.getTracks();
												for(var i in tracks) {
													var mst = tracks[i];
													if(mst)
														mst.stop();
												}
											} catch(e) {}
										}
										//$('#remotevideo' + mid).remove();
										if(track.kind === "video") {
										}
										delete player_janus_params.remoteTracks[mid];
										return;
									}


									// If we're here, a new track was added
									var stream = null;

									if(track.kind === "audio") {
										// New audio track: create a stream out of it, and use a hidden <audio> element
										stream = new MediaStream([track]);
										player_janus_params.remoteTracks[mid] = stream;
										Janus.log("Created remote audio stream:", stream);
										//$('#streams').append('<audio class="hidden" id="remotevideo' + mid + '" playsinline/>');
										//$('#remotevideo'+mid).css('display', 'block');
										$('#remotevideo'+mid).get(0).volume = 0;
									} 

									if(track.kind === "video") {
										// New video track: create a stream out of it
										stream = new MediaStream([track]);
										Janus.log("Created remote video stream:", stream);

										// Use a custom timer for this stream
										if(!player_janus_params.bitrateTimer[mid]) {
											player_janus_params.bitrateTimer[mid] = setInterval(function() {
												if(!$("#remotevideo" + mid).get(0)) return;
												// Display updated bitrate, if supported
												var bitrate = player_janus_params.streaming.getBitrate(mid);
												$('#curbitrate'+mid).text(bitrate);
												// Check if the resolution changed too
												var width = $("#remotevideo" + mid).get(0).videoWidth;
												var height = $("#remotevideo" + mid).get(0).videoHeight;
												if(width > 0 && height > 0) $('#curres'+mid).text(width+'x'+height);

												if (mid == 'v1') {
													//$("#remotevideo" + mid).css('width', '100%');
													//$("#remotevideo" + mid).css('height', '100%');
												}

												if (mid == 'v2') {
													$("#remotevideo" + mid).css('width', '320px');
													$("#remotevideo" + mid).css('height', '200px');
												}

											}, 1000);
										}
									}

									// Play the stream
									$("#remotevideo" + mid).bind("playing", function (ev) {
										if(!this.videoWidth) return;
										var width = this.videoWidth;
										var height = this.videoHeight;
										$('#curres'+mid).text(width+'x'+height);

										$('#remotevideo' + mid).css('display', 'block');
										//$('#audio_icons_area').css('display', 'inline');

										if(Janus.webRTCAdapter.browserDetails.browser === "firefox") {
											// Firefox Stable has a bug: width and height are not immediately available after a playing
											setTimeout(function() {
												var width = $('#'+ev.target.id).get(0).videoWidth;
												var height = $('#'+ev.target.id).get(0).videoHeight;
												$('#curres'+mid).text(width+'x'+height);
											}, 2000);
										}
									});

									Janus.attachMediaStream($('#remotevideo' + mid).get(0), stream);
									$('#remotevideo' + mid).get(0).play();
									$('#remotevideo' + mid).get(0).volume = 1;
								},

								oncleanup: function() {
									Janus.log(" ::: Got a cleanup notification :::");

									$('#remotevideo' + mid).css('display', 'none');

									for(var i in player_janus_params.bitrateTimer) clearInterval(player_janus_params.bitrateTimer[i]);

									player_janus_params.bitrateTimer = {};
									player_janus_params.remoteTracks = {};
								}
							});
					},

					error: function(error) {
						alert(error);
						//reload_page();
					},

				});
	}});
}


function reload_page() {
	window.location.reload();
}


function updateStreamsList() {
	var body = { request: "list" };

	Janus.debug("Sending message:", body);

	player_janus_params.streaming.send({ message: body, success: function(result) {

		if(!result) {
			alert("Got no response to our query for available streams");
			return;
		}

		if(result["list"]) {
			var list = result["list"];

			Janus.log("Got a list of available streams:", list);

			player_janus_params.streamsList = {}

			for(var mp in list) {

				// Check the nature of the available streams, and if there are some multistream ones
				list[mp].legacy = true;

				if(list[mp].media) {

					var audios = 0, videos = 0;

					for(var mi in list[mp].media) {
						if(!list[mp].media[mi])
							continue;
						if(list[mp].media[mi].type === "audio")
							audios++;
						else if(list[mp].media[mi].type === "video")
							videos++;
						if(audios > 1 || videos > 1) {
							list[mp].legacy = false;
							break;
						}
					}
				}

				// Keep track of all the available streams
				player_janus_params.streamsList[list[mp]["id"]] = list[mp];
			}

		}

		PlayerWebrtcPlay();
	}});
}

function getStreamInfo() {
	if(!player_janus_params.selectedStream || !player_janus_params.streamsList[player_janus_params.selectedStream]) {
		alert('getStreamInfo failed');
		return;
	}

	// Send a request for more info on the mountpoint we subscribed to
	var body = { request: "info", id: parseInt(player_janus_params.selectedStream) || player_janus_params.selectedStream };

	player_janus_params.streaming.send({ message: body, success: function(result) {
		console.log('getStreamInfo: ', result);
		if(result && result.info && result.info.metadata) {
			//alert('stream info: ' + escapeXmlTags(result.info.metadata));
		}
	}});
}

function PlayerWebrtcStartStream(stream_id) {
	player_janus_params.selectedStream = stream_id;

	Janus.log("Selected video id #" + player_janus_params.selectedStream);

	if(!player_janus_params.selectedStream || !player_janus_params.streamsList[player_janus_params.selectedStream]) {
		alert("Select a stream from the list");
		return;
	}

	// Add some panels to host the remote streams
	if(player_janus_params.streamsList[player_janus_params.selectedStream].legacy) {
		// At max 1-audio/1-video, so use a single panel
		var mid = null;
		for(mi in player_janus_params.streamsList[player_janus_params.selectedStream].media) {
			// Add a new panel
			var type = player_janus_params.streamsList[player_janus_params.selectedStream].media[mi].type;
			if(type === "video") {
				mid = player_janus_params.streamsList[player_janus_params.selectedStream].media[mi].mid;
				break;
			}
		}
	}

	// Prepare the request to start streaming and send it
	var body = { request: "watch", id: parseInt(player_janus_params.selectedStream) || player_janus_params.selectedStream };
	// Notice that, for RTP mountpoints, you can subscribe to a subset
	// of the mountpoint media, rather than them all, by adding a "stream"
	// array containing the list of stream mids you're interested in, e.g.:
	//
	//		body.streams = [ "0", "2" ];
	//
	// to only subscribe to the first and third stream, and skip the second
	// (assuming those are the mids you got from a "list" or "info" request).
	// By default, you always subscribe to all the streams in a mountpoint
	player_janus_params.streaming.send({ message: body });

	// Get some more info for the mountpoint to display, if any
	getStreamInfo();
}

function stopStream() {
	var body = { request: "stop" };
	player_janus_params.streaming.send({ message: body });
	player_janus_params.streaming.hangup();
}

// Helper to escape XML tags
function escapeXmlTags(value) {
	if(value) {
		var escapedValue = value.replace(new RegExp('<', 'g'), '&lt');
		escapedValue = escapedValue.replace(new RegExp('>', 'g'), '&gt');
		return escapedValue;
	}
}
