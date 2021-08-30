from .handlers.index import IndexHandler
from .handlers.status import StatusHandler

index = IndexHandler()
status = StatusHandler()


def setup_routes(app):
    app.router.add_route('GET', '/', index.handler)
    app.router.add_route("POST", "/", index.on_post_handler)
    app.router.add_route('GET', '/status', status.handler)
