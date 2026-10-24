"""Local FoodTrail server with HTTP byte-range support for PMTiles."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os

ROOT = Path(__file__).resolve().parent
os.chdir(ROOT)

class RangeHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return super().send_head()
        try:
            f = open(path, 'rb')
        except OSError:
            self.send_error(404, 'File not found')
            return None
        fs = os.fstat(f.fileno())
        size = fs.st_size
        range_header = self.headers.get('Range')
        if range_header and range_header.startswith('bytes='):
            try:
                spec = range_header.split('=', 1)[1].split(',', 1)[0]
                start_s, end_s = spec.split('-', 1)
                if start_s == '':
                    length = int(end_s)
                    start = max(0, size - length)
                    end = size - 1
                else:
                    start = int(start_s)
                    end = min(int(end_s), size - 1) if end_s else size - 1
                if start >= size or start > end:
                    raise ValueError()
            except Exception:
                f.close()
                self.send_response(416)
                self.send_header('Content-Range', f'bytes */{size}')
                self.end_headers()
                return None
            self.send_response(206)
            self.send_header('Content-Type', self.guess_type(path))
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
            self.send_header('Content-Length', str(end - start + 1))
            self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
            self.end_headers()
            f.seek(start)
            return _LimitedReader(f, end - start + 1)
        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(path))
        self.send_header('Content-Length', str(size))
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
        self.end_headers()
        return f

class _LimitedReader:
    def __init__(self, fileobj, remaining):
        self.fileobj, self.remaining = fileobj, remaining
    def read(self, amount=-1):
        if self.remaining <= 0:
            return b''
        if amount < 0 or amount > self.remaining:
            amount = self.remaining
        data = self.fileobj.read(amount)
        self.remaining -= len(data)
        if self.remaining <= 0:
            self.fileobj.close()
        return data
    def close(self):
        self.fileobj.close()

if __name__ == '__main__':
    server = ThreadingHTTPServer(('127.0.0.1', 8765), RangeHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
