# resrepo

# Research repository (resrepo) template

The aim of `resrepo` is to encourage and facilitate good practices when
setting up and managing `git` repositories for scientific research
projects. Scientific projects contain both code and data. `git` is
designed to manage software code, but it is not suited to track large
data files. There are extensions of `git`, such as `git-lfs` and
`git-annex` that can handle data, but they can be complex to set up and
difficult to use, especially when sharing your repository among
collaborators. `resrepo` encourages good habits to manage your data
alongside your code in plain `git`, ensuring reproducible science and a
tidy repository that can used for publication of your project.

## Install the library

`resrepo` is still under development and is not yet available on CRAN.
You can get a preview from GitHub; it is reasonably complete, and we
already use it for our own projects, but please beware that it is under
testing. With `pak`, you can simply use:

    pak::pak("EvolEcolGroup/resrepo")

## Overview of functionality

You can build the vignettes when installing `resrepo` (note that you
will need to have the necessary tools to build vignettes already
installed; requirements depend on your OS):

    devtools::install_github("EvolEcolGroup/resrepo", build_vignette = TRUE)

If you built the vignettes, you can read them directly in R. For
example, the overview of the workflow can be obtained with:

    vignette("resrepo", package = "resrepo")
