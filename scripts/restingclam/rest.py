import clamd
import logging
import sys
import timeit

from flask import Flask, request
from flask_restful import Resource, Api, abort

app = Flask(__name__)
api = Api(app)

host = '127.0.0.1'
port = 10101

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
logger = logging.getLogger("AV")

def get_socket():

    try:
        socket = clamd.ClamdUnixSocket('/run/clamav/clamd.sock')
        return socket
    except:
        logger.exception('Failed to connect to clamd')
        abort(502)

class HeartBeatAPI(Resource):

    def get(self):

        socket = get_socket()

        try:
            r = socket.ping()

            if r == 'PONG':
                return 200
            else:
                abort(502)

        except clamd.ConnectionError:
            abort(502)

        except BaseException as e:
            abort(500)

class ScanFileAPI(Resource):

    def post(self):

        if len(request.files) != 1:
            abort(400)

        socket = get_socket()

        _, data = list(request.files.items())[0]
        filename = data.filename
        logger.info("Scanning {}".format(filename))

        start = timeit.default_timer()
        result = socket.instream(data)
        end = timeit.default_timer()
        elapse = end - start

        # this is fine because requests only originate from trusted VLAN IPs
        if request.headers.getlist("X-Forwarded-For"):
            ip = request.headers.getlist("X-Forwarded-For"):
        else:
            ip = request.remote_addr

        result = "OK" if result["stream"][0] == "OK" else "NOTOK"

        logger.info("Scan of {} complete (originating from {}). Time: {}. Status: {}".format(filename, ip, elapse, result))

        return result

api.add_resource(HeartBeatAPI, '/heartbeat')
api.add_resource(ScanFileAPI, '/scan')

if __name__ == '__main__':
    app.run(debug=True)
