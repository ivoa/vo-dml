Installation
============

The VO-DML tooling is based around [gradle](https://gradle.org) (currently version 8) which itself
is based on Java. It is recommended that a minimum of JDK 17 is installed 
using a package manager for your OS and 
similarly use a package manager for gradle installation. Although if you are working
with a repository that already has a `gradelw` file at the top level, then that can be used
in place of the gradle command, and it will handle the downloading and running of the correct gradle version. 

The functionality of the tooling is then encapsulated with a gradle plugin which
is configured [in the quickstart instructions](QuickStart.md)

Note the documentation tasks of the tools that produce the overall model diagram also require that [graphviz](https://graphviz.org)  be installed. 

If full documentation site generation is required then [mkdocs material theme](https://squidfunk.github.io/mkdocs-material/getting-started/) is needed as an external installation dependency along with [yq](https://github.com/mikefarah/yq/#install) that can be used to automate the mkdocs navigation menu creation.