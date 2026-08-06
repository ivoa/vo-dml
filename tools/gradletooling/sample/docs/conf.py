#  Copyright (c) 2026. Paul Harrison, University of Manchester
project = 'VO-DML Documentation View'
author = 'Paul Harrison'

#html_theme = 'classic'

html_static_path = ['_static']

html_css_files = [
    'css/test.css',
]

extensions = [
    'sphinxcontrib.plantuml',
    'sphinx_diagram_connect',
    'sphinxcontrib.imagesvg',
]

plantuml_output_format = 'svg'
plantuml_batch_size = 10
