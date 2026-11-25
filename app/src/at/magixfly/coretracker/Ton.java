package at.magixfly.coretracker;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;

/** V2.36: warning tones played by Android itself (the WebView sound stayed silent on the box) - V2.43: played as media like Spotify (the navigation channel stayed silent on the box) */
class Ton {
    static final int SR = 22050;

    static void play(final Context c, final int kind) {
        new Thread(new Runnable() { public void run() {
            try {
                double[][] n = kind == 2 ? new double[][]{{988, 0}, {784, .22}, {659, .44}} : new double[][]{{880, 0}, {1175, .18}};
                double len = kind == 2 ? 1.0 : .7;
                short[] pcm = new short[(int) (SR * len)];
                for (double[] f : n) {
                    int s0 = (int) (f[1] * SR), sl = (int) (.45 * SR);
                    for (int i = 0; i < sl && s0 + i < pcm.length; i++) {
                        double t = i / (double) SR, env = Math.min(1, t / .02) * Math.exp(-t * 7);
                        int v = pcm[s0 + i] + (int) (Math.sin(2 * Math.PI * f[0] * t) * env * 12000);
                        pcm[s0 + i] = (short) Math.max(-32767, Math.min(32767, v));
                    }
                }
                AudioManager am = (AudioManager) c.getSystemService(Context.AUDIO_SERVICE);
                AudioAttributes aa = new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build();
                am.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK);
                AudioTrack tr = new AudioTrack(aa, new AudioFormat.Builder().setSampleRate(SR).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build(),
                        pcm.length * 2, AudioTrack.MODE_STATIC, AudioManager.AUDIO_SESSION_ID_GENERATE);
                tr.write(pcm, 0, pcm.length);
                tr.play();
                Thread.sleep((long) (len * 1000) + 150);
                tr.release();
                am.abandonAudioFocus(null);
            } catch (Throwable t) { android.util.Log.d("CTTON", "" + t); }
        } }).start();
    }
}
