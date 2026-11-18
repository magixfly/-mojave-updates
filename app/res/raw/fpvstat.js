/* V3.07 / App 1.77 (Jmuxer catch-up) – V3.05 / App 1.75: FPV stall meter for the CosmoStreamer page (Janus / Pion / Jmuxer).
   Counts freezes (no new video frame for > 300 ms), longest freeze, WebRTC packet loss; small overlay top left;
   one log line per minute (console "CTSTAT ..."; in the tracker also POST /api/dbg). */
(function () {
  if (window.ctStatOn) return; window.ctStatOn = 1;
  var PCS = window.ctPCs = window.ctPCs || [];
  try {   // remember every WebRTC connection the player opens (needed for packet loss)
    var R = window.RTCPeerConnection;
    if (R && !R.prototype.__ct) {
      var o = R.prototype.setRemoteDescription;
      R.prototype.setRemoteDescription = function () { if (PCS.indexOf(this) < 0) PCS.push(this); return o.apply(this, arguments); };
      R.prototype.__ct = 1;
    }
  } catch (e) {}
  var NAMES = { '0': 'Jmuxer', '1': 'Janus', '2': 'Pion' };
  function mode() { return (document.cookie.match(/video_player_mode=(\d)/) || [])[1] || '1'; }
  var ev = [], lastF = 0, inFreeze = false, frames = 0, watched = null, loss = null, lost0 = null, recv0 = null, t0 = Date.now(), fz = null;
  function active() {
    var v = [].slice.call(document.querySelectorAll('video')).filter(function (x) { return x.videoWidth > 0; });
    v.sort(function (a, b) { return b.videoWidth * b.videoHeight - a.videoWidth * a.videoHeight; });
    return v[0];
  }
  function onFrame() { var n = Date.now(); if (inFreeze) { ev.push([n, n - lastF]); inFreeze = false; } lastF = n; frames++; }
  function hook(v) {
    watched = v; lastF = Date.now();
    if (v.requestVideoFrameCallback) { var f = function () { if (watched !== v) return; onFrame(); v.requestVideoFrameCallback(f); }; v.requestVideoFrameCallback(f); }
    else { var q = 0; setInterval(function () { if (watched !== v) return; var p = v.getVideoPlaybackQuality ? v.getVideoPlaybackQuality().totalVideoFrames : 0; if (p !== q) { q = p; onFrame(); } }, 50); }
  }
  setInterval(function () {
    var v = active(); if (!v) return;
    if (v !== watched) hook(v);
    if (!inFreeze && Date.now() - lastF > 300 && !document.hidden) inFreeze = true;
  }, 100);
  setInterval(function () {   // packet loss of the video stream (WebRTC only)
    PCS.forEach(function (pc) {
      if (!pc.getStats || pc.connectionState === 'closed') return;
      pc.getStats().then(function (r) {
        r.forEach(function (s) {
          if (s.type === 'inbound-rtp' && (s.kind || s.mediaType) === 'video') {
            if (lost0 === null) { lost0 = s.packetsLost; recv0 = s.packetsReceived; }
            var l = s.packetsLost - lost0, rc = s.packetsReceived - recv0;
            loss = rc + l > 0 ? 100 * l / (rc + l) : 0;
            if (s.freezeCount !== undefined) fz = s.freezeCount;
          }
        });
      }).catch(function () {});
    });
  }, 2000);
  // Jmuxer: plays from a buffer and drifts behind live (2 s and more) - keep it close to live:
  // behind = play up to 2x faster until caught up (V3.08: no seeking)
  window.ctLag = null;
  setInterval(function () {
    if (mode() !== '0') { window.ctLag = null; return; }
    var v = document.getElementById('video_element');
    if (!v || !v.buffered || !v.buffered.length) return;
    var end = v.buffered.end(v.buffered.length - 1), lag = end - v.currentTime;
    window.ctLag = lag;
    try {
      // no jumping (seeking in the stream gave a black picture) - only play faster until caught up
      v.playbackRate = lag > 1.5 ? 2 : lag > 0.6 ? 1.5 : lag > 0.25 ? 1.2 : 1;
    } catch (e) {}
  }, 250);
  var box = document.createElement('div');
  box.style.cssText = 'position:fixed;left:8px;top:8px;z-index:2147483647;visibility:visible!important;pointer-events:none;font:700 15px/1.3 sans-serif;color:#4ade80;background:rgba(0,0,0,.55);padding:3px 9px;border-radius:7px;white-space:nowrap';
  function text() {
    var n = Date.now(), w = ev.filter(function (e) { return n - e[0] < 600000; }), mx = 0;
    w.forEach(function (e) { if (e[1] > mx) mx = e[1]; });
    var s = NAMES[mode()] + ' · ' + w.length + ' freezes / 10 min' + (w.length ? ' · max ' + (mx / 1000).toFixed(1) + ' s' : '');
    if (loss !== null && mode() !== '0') s += ' · loss ' + loss.toFixed(1) + ' %';
    if (window.ctLag !== null) s += ' · buffer ' + window.ctLag.toFixed(1) + ' s';
    box.style.color = w.length ? (mx > 700 ? '#f87171' : '#fbbf24') : '#4ade80';
    return { s: s, lag: window.ctLag, n10: w.length, max: mx, all: ev.length, loss: loss, mins: Math.round((n - t0) / 60000) };
  }
  setInterval(function () { if (!box.parentNode && document.body) document.body.appendChild(box); var t = text(); box.textContent = t.s; box.style.display = window.ctStatHide ? 'none' : ''; }, 1000);
  setInterval(function () {
    var t = text(); t.player = NAMES[mode()];
    console.log('CTSTAT ' + JSON.stringify(t));
    if (location.pathname.indexOf('/cosmo') === 0) try { fetch('/api/dbg', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ fpvstat: t }) }); } catch (e) {}
  }, 60000);
})();
