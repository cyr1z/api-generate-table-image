from os import getenv

from dotenv import load_dotenv

load_dotenv()


class Config:
    port = getenv('PORT')
    production = getenv('PROD')
    project = getenv('PROJECT_NAME', 'default')
    base_url = getenv('BASE_URL')
    storage_dir = getenv('STORAGE_DIR')
    token = getenv('TOKEN')
