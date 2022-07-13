# ${REPO}

## Overview

$README_OVERVIEW

### Using This Template

This Template repo is intended to be used with our Terraform Module which will create additional settings which aspects of this template will require in order to function properly.

Once this template has been used to create a new repo, follow this todo list to ensure all templated items are updated and replaced with your repo specific content:

- [ ] Add this repo to the Solution Center Catalog.  See https://pages.github.boozallencsn.com/uip/uip-studio-technical-docs/reference/portal/defining-entity/?h=catalog
    - Update The catalog-info.yaml file's placeholders
    - Log into the Solution Center and import your repo
- [ ] Replace the @var@ tagged variables in this file with the specific content for your repo.
- [ ] Remove this section from this README.md file

## Required Inputs

${README_INPUTS}

## Outputs

${README_OUTPUTS}

## Contributing

This project follows a fork-based contribution model, also called a [Fork and Pull Model][1].  Please see [fork-based.md][2] for specific details for this project.

## Release Process

This project follows the [Sementatic Versioning][3] based on the type of changes introduced for that release.

We aim to tag and release a new version every sprint which contains closed PR's to the main branch.  Please see [release-process.md][4] for specific details for this project.

[1]: https://docs.github.com/en/github/collaborating-with-pull-requests/getting-started/about-collaborative-development-models#fork-and-pull-model
[2]: fork-based.md
[3]: https://semver.org
[4]: release-process.md