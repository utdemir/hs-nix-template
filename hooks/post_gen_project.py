import os
import sys

REMOVE_PATHS = [
    '{% if cookiecutter.project_configuration_tool.startswith("package.yaml") %} {{ cookiecutter.project_name }}.cabal {% endif %}',
    '{% if not cookiecutter.project_configuration_tool.startswith("package.yaml") %} package.yaml {% endif %}',
    '{% if cookiecutter.add_executable_section == "no" %} app/Main.hs {% endif %}',
    '{% if cookiecutter.add_executable_section == "no" %} app {% endif %}',
]

for path in REMOVE_PATHS:
    path = path.strip()
    if path and os.path.exists(path):
        if os.path.isdir(path):
            os.rmdir(path)
        else:
            os.unlink(path)
