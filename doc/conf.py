# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project   = 'TSMP1_WorkflowEngine'
copyright = '2023, Niklas WAGNER'
author    = 'Niklas WAGNER'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
        'sphinx.ext.autodoc',
        'sphinx.ext.viewcode',
        'sphinx_rtd_theme',
        'sphinx.ext.napoleon',
        'sphinx.ext.mathjax',
        'sphinx_copybutton',
        'myst_parser'
        ]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
source_suffix = ['.rst', '.md']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
#
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = []

html_context = {
    "display_github": True, # Integrate GitHub
    "github_user": "HPSCTerrSys", # Username
    "github_repo": "TSMP1_WorkflowEngine", # Repo name
    "github_version": "main", # Version
    "conf_py_path": "/doc/", # Path in the checkout to the docs root
}

napoleon_numpy_docstring = True
napoleon_use_ivar = True

copybutton_prompt_text = (r">>> |\.\.\. |\$ |" +
                          r"In \[\d*\]: | {2,5}\.\.\.: | {5,8}: ")
copybutton_prompt_is_regexp = True

html_show_sourcelink = True

# MyST generates link anchors from MarkDown headings
myst_heading_anchors = 4

myst_enable_extensions = [
    "amsmath",                  # LaTeX equations
    "dollarmath",               # Inline LaTex
]
