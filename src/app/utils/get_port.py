"""

get_port()

- returns the port number passed in the -p or --port arguments

- or returns the port number specified in the PORT environment variable
  (loads environment variables from the .env file)
- or returns the value of the DEFAULT_PORT constant

"""

from argparse import ArgumentParser
from os import getenv

from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.

DEFAULT_PORT = 8080


def get_port_from_env():
    try:
        return int(getenv('PORT'))
    except (TypeError, ValueError):
        pass


def get_port_from_args():
    parser = ArgumentParser()
    parser.add_argument("-p", "--port", help="set port for this app")
    args = parser.parse_args()
    try:
        return int(args.port)
    except (TypeError, ValueError):
        pass


def get_port():
    return get_port_from_args() or get_port_from_env() or DEFAULT_PORT
