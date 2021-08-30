from aiohttp import web
from app.app import create_app
from app.utils.get_port import get_port
from app.logger.logger import run_logger

run_logger()

app = create_app()

if __name__ == '__main__':
    web.run_app(app, port=get_port())
