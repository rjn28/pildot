# Contributing to Pildot

Bug reports and focused improvements are welcome. Pildot is a small personal macOS project, distributed as source code.

## Report a bug

[Open an issue](https://github.com/rjn28/pildot/issues/new/choose) with:

- What you expected and what actually happened.
- Steps to reproduce the problem.
- Your macOS version and Mac architecture (Apple Silicon or Intel).
- Your Swift version (`swift --version`) if the problem involves building.
- Relevant logs or a screenshot, with personal information removed.

For a larger feature or design change, open an issue first so its scope can be discussed before implementation.

## Submit a change

1. Fork the repository and create a branch for your change.
2. Keep the change focused and follow the existing Swift style.
3. Update documentation when behavior or build instructions change.
4. Add or update tests when they help verify a behavior change.
5. Run the checks below, then open a pull request explaining the change and how you verified it.

```bash
swift build
swift test
bash -n package.sh script/build_app_bundle.sh script/build_and_run.sh
./script/build_app_bundle.sh release
```

For menu bar changes, also run `./script/build_and_run.sh --verify` in a graphical macOS session and inspect the menu and indicator. A running process alone does not verify appearance.

Do not commit generated app bundles, disk images, local configuration, credentials, or signing material. The project currently uses only system frameworks; explain the need for any proposed dependency.

Use short, descriptive commit messages, such as `fix: correct battery status text` or `docs: clarify local build steps`.
