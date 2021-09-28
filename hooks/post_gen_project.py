import os
import sys

REMOVE_PATHS = [
    '{% if cookiecutter.use_hpack == "y" %} {{ cookiecutter.project_name }}.cabal {% endif %}',
    '{% if cookiecutter.use_hpack != "y" %} package.yaml {% endif %}',
]

for path in REMOVE_PATHS:
    path = path.strip()
    if path and os.path.exists(path):
        if os.path.isdir(path):
            os.rmdir(path)
        else:
            os.unlink(path)
