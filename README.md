# sass-to-scss

## Usage

```
pnpm dlx sass-to-scss [-w|--write] [-x <glob>|--exclude=<glob>...] [-n|--no-verify] [--no-rename]
```

All .sass files and `<style lang="sass">` blocks in .vue files in the current directory and subdirectories will be converted to .scss syntax.

## Options

### `--write` (`-w`)

Write the conversion to disk. Without this option this tool just verifies that your sass files will compile to the same CSS after conversion.

**This WILL overwrite your code, make sure you have no uncommitted changes first.**

### `--exclude=<glob>` (`-x <glob>`)

Exclude files matching `<glob>`, passed to [tinyglobby](npmjs.com/package/tinyglobby)'s `ignore` option. `**/node_modules/**` is always excluded. Specify multiple times to exclude more than one glob.

### `--no-verify` (`-n`)

Skip compiling to CSS before and after conversion. Use this if there are conversion errors you don't care about or want to fix manually afterwards.

### `--no-rename`

Create .scss files next to the original .sass instead of overwriting them. May need to be combined with `--no-verify` if you have imports that don't specify a file extension.
