"""Controls an mpv player through its JSON IPC socket (video and audio player of ShowPlayPI)."""

import json
import socket
import subprocess
import time
from pathlib import Path


class Mpv:
    """Starts mpv with the given options and talks to it over input-ipc-server."""

    def __init__(self, socket_path, options):
        self.socket_path = Path(socket_path)
        self.socket_path.unlink(missing_ok=True)
        self.process = subprocess.Popen(["mpv", *options, f"--input-ipc-server={self.socket_path}"])
        self.connection = None
        for _ in range(100):
            try:
                self.connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.connection.connect(str(self.socket_path))
                break
            except OSError:
                self.connection.close()
                self.connection = None
                if self.process.poll() is not None:
                    raise RuntimeError("mpv could not be started")
                time.sleep(0.1)
        if self.connection is None:
            raise RuntimeError("no connection to mpv")
        self.connection.settimeout(2)
        self.buffer = b""
        self.events = []
        self.request = 0

    def _read_line(self):
        while b"\n" not in self.buffer:
            chunk = self.connection.recv(65536)
            if not chunk:
                raise RuntimeError("mpv has stopped")
            self.buffer += chunk
        line, self.buffer = self.buffer.split(b"\n", 1)
        return json.loads(line)

    def command(self, *arguments):
        self.request += 1
        request = self.request
        self.connection.sendall(json.dumps({"command": list(arguments), "request_id": request}).encode() + b"\n")
        while True:
            message = self._read_line()
            if "event" in message:
                self.events.append(message)
            elif message.get("request_id") == request:
                if message.get("error") not in (None, "success"):
                    return None
                return message.get("data")

    def get(self, name):
        return self.command("get_property", name)

    def set(self, name, value):
        self.command("set_property", name, value)

    def take_events(self):
        """Events received so far (non-blocking)."""
        self.connection.setblocking(False)
        try:
            while True:
                try:
                    chunk = self.connection.recv(65536)
                except BlockingIOError:
                    break
                if not chunk:
                    raise RuntimeError("mpv has stopped")
                self.buffer += chunk
        finally:
            self.connection.settimeout(2)
        while b"\n" in self.buffer:
            line, self.buffer = self.buffer.split(b"\n", 1)
            message = json.loads(line)
            if "event" in message:
                self.events.append(message)
        events, self.events = self.events, []
        return events
