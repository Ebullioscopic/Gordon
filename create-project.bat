ECHO Creating Project
python -m pip install --upgrade pip setuptools virtualenv
python -m virtualenv kivy_venv
call kivy_venv/Scripts/activate
python -m pip install "kivy[full]" kivy_examples
python -m pip install kivymd
python -m pip install kivymd-extensions.akivymd
