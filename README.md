Docker Github Actions Runner - Lithic Edition
============================

A dockerized action runner based on [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner) with minimal tweaks to support Lithic workflows. The project is covered in more detail in [privacy-com/pulumi-github-actions-runner](https://github.com/privacy-com/pulumi-github-actions-runner)

### Main differences from original repo ###
* Runners are uniquely named with a UUID suffix
* A GitHub PAT is passed into the container to set up `.gitconfig`
* Additional packages installed to support builds

## Notes ##

This is a **public** repo, and sensitive values should be handled accordingly. Right now that is being done via [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

Included below are some caveats to using this runner in workflows, duplicated from the original repo.

### Security ###

It is known that currently tokens (ACCESS_TOKEN / RUNNER_TOKEN ) are not safe from exfiltration.
If you are using this runner make sure that any workflow changes are gated by a verification process (in the actions settings) so that malicious PR's cannot exfiltrate these.

### Docker Support ###

Please note that while this runner installs and allows docker, github actions itself does not support using docker from a self hosted runner yet.
For more information:

* https://github.com/actions/runner/issues/406
* https://github.com/actions/runner/issues/367

Also, some GitHub Actions Workflow features, like [Job Services](https://docs.github.com/en/actions/guides/about-service-containers), won't be usable and [will result in an error](https://github.com/myoung34/docker-github-actions-runner/issues/61).

### Containerd Support ###

Currently runners [do not support containerd](https://github.com/actions/runner/issues/1265)

***LINK TO DOCKER IMAGE LIST HERE ***

## Examples ##

### Note ###

If you're using a RHEL based OS with SELinux, add `--security-opt=label=disable` to prevent [permission denied](https://github.com/myoung34/docker-github-actions-runner/issues/9)

## Usage From GH Actions Workflow ##

```yml
name: Package

on:
  release:
    types: [created]

jobs:
  build:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v1
    - name: build packages
      run: make all
```

