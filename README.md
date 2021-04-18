# Cryfs Tap

This is a homebrew tap to install CryFS ([repository](https://github.com/cryfs/cryfs), [homepage](https://cryfs.org)) on MacOS.

## How do I install CryFS using this tap?

`brew install cryfs/tap/cryfs`

Or `brew tap cryfs/tap` and then `brew install cryfs`.

## Homebrew Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## How do I update this formula to a new version?

To update, don't just merge into the main branch, but create a PR.
The PR CI will build bottles and store them as build artifacts.

Once the PR passes CI, label it with the "pr-pull" label.
The labeling will trigger a Github Action to add the bottles from the artifacts to the Formula and merge the PR into the main branch.
