# Contributing

Thanks for your interest in improving Token Usage Menubar.

## License

By contributing, you agree that your contributions will be licensed under the
same license as the project (**GNU GPLv3**). See `LICENSE` and `NOTICE`.

## Workflow

1. Open an issue before large changes so we can agree on direction.
2. Fork the repository and create a branch.
3. Build locally with `swift build` or Xcode.
4. Keep commits focused; use clear messages.
5. Open a pull request describing what changed and why.

## Code style

- Match existing Swift formatting and naming.
- Prefer small, reviewable diffs.

## Releases

Maintainers cut releases with **annotated git tags** `vMAJOR.MINOR.PATCH` (for example `v1.0.0`).
Pushing a tag builds the Apple Silicon binary and attaches it to a GitHub Release automatically.
