import pyaudio
import wave
from datetime import datetime
from time import sleep

FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100
CHUNK = 1024
RECORD_SECONDS = 5
WAVE_OUTPUT_FILENAME = "file.wav"

class VIspeaker( object ):
    def __init__(self):
        self._frames = []
        self._audio_context = None
        self._stream = None
        self._record_thread = None
        self._recording_flag = False
        self._record_quit_flag = False
        self._record_running = False
        self._sigint_sent = False

    def start_recording(self):
        self._frames = []
        self._audio_context = pyaudio.PyAudio()
        self._stream = self._audio_context.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=RATE,
            input=True,
            frames_per_buffer=CHUNK
        )

    def save_frames(self):
        if self._stream is not None:
            data = self.stream.read(CHUNK)
            self._frames.append(data)

    def cleanup(self):
        if self._stream is not None:
            self._stream.stop_stream()
            self._stream.close()
            self._stream = None

        if self._audio_context is not None:
            self._audio_context.terminate()

    def stop_recording(self):
        if (self._stream is None or self.audio_context is None
            or not self.frames):
            return 'record never start, dump failed'

        self._stream.stop_stream()
        self._stream.close()
        self._audio_context.terminate()

        now = datetime.now()
        output_file = "test_" + now.strftime("%m%d-%H%M%S") + ".wav"
        wf = wave.open(output_file, 'wb')
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(self._audio_context.get_sample_size(FORMAT))
        wf.setframerate(RATE)
        wf.writeframes(b''.join(self._frames))
        wf.close()
        return 'succuss, save to file ' + output_file

    def trap_sigint(self):
        def signal_handler(*args, **kwargs):
            self._sigint_sent = True

    def run_record(self):
        self._record_running = True
        self._record_quit_flag = False
        while True:
            if self._sigint_sent or self._record_quit_flag:
                break

            if self._recording_flag:
                self.save_frames()
            else:
                sleep(0.05) # pause a little bit time to save power

        self.cleanup()
        self._record_running = False # reset flag

    def start_record(self):
        if not self._audio_context or not self._stream:
            self.start_recording()
        self._recording_flag = True

    def pause_record(self):
        self._recording_flag = False

    def quit_record(self):
        self._record_quit_flag = True
