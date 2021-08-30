"""
Handler for index pages
"""
import os

import dataframe_image
from aiohttp import web
from app.config import Config
from loguru import logger
from pandas import DataFrame
from slugify import slugify


def data_to_image(header, columns, values, filename):
    values = [columns, *values]
    df = DataFrame(values, columns=columns)
    df = df.loc[1:]
    df = df.style.set_caption(header).set_precision(2)
    dataframe_image.export(df, Config.storage_dir + "/" + filename)


class IndexHandler:

    @staticmethod
    async def handler(request):
        """
         return image if it exists

        """
        img = request.rel_url.query.get('img')
        if not img:
            raise web.HTTPFound('/status')
        file_path = Config.storage_dir + "/" + img
        if not os.path.isfile(file_path):
            logger.warning(file_path + ' not found')
            raise web.HTTPNotFound()
        return web.FileResponse(file_path)

    @staticmethod
    async def on_post_handler(request):
        """
         generate image with table from json post
         and return json with image link

        """
        if not request.body_exists:
            raise web.HTTPNotFound()

        request_data = await request.json()

        token = request_data.get('token')
        if token != Config.token:
            raise web.HTTPNotFound()

        columns = request_data.get('columns')
        header = request_data.get('header')
        values = request_data.get('values')
        filename = slugify(header, to_lower=True) + "-table.png"

        data_to_image(header, columns, values, filename)

        return web.json_response({'image': Config.base_url + '/?img=' + filename})
