from os import environ
from flask import Flask
import requests, json, os

app = Flask(__name__)


@app.route('/')
def hello_geek():
    try:
        api = os.environ.get('API_URL', 'http://localhost:8081/')
        print(f'Attempting connection to {api}', flush=True)
        api = requests.get(api)
        body = json.loads(api.content)
        user = body["user"]
    except:
        user = 'Anon'

    return f'<h1>Hello {user}!</h2>'


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
