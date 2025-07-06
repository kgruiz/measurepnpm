# measurepnpm

`measurepnpm` is a Zsh function that walks through your project’s `node_modules/.pnpm` directory, measures the on-disk size of every package (as stored by pnpm), and prints a sorted table of package sizes along with a live progress indicator.

---

## Features

- 🔍 **Accurate**: Reads actual disk usage from pnpm’s store
- ⚡ **Fast**: Uses `find` + `du` in tandem for minimal overhead
- 📊 **Pretty**: Live spinner & count, colourized output
- 📈 **Human-readable**: Prints sizes in K, M, or G as appropriate
- 🎯 **Flexible**:
  - Show only the pnpm store path
  - Point at an arbitrary project / `node_modules` / `.pnpm` directory

---

## Requirements

- **Zsh** (tested on zsh 5.8+)
- **pnpm** (for getting the store path)
- Unix tools: `find`, `du`, `realpath`, `awk`, `sort`

---

## Installation

1. **Copy** `measurepnpm.zsh` into your Zsh functions folder (e.g. `~/.zsh-Functions/`).
2. **Source** it from your `.zshrc`:

   ```zsh
   fpath=(~/.zsh-Functions $fpath)
   autoload -Uz measurepnpm
   ```

3. **Reload** your shell:

   ```bash
   source ~/.zshrc
   ```

---

## Usage

```bash
measurepnpm [ -h | --help ] [ -s | --store ] [ <path> ]
```

- `-h`, `--help`
  Show help message and exit
- `-s`, `--store`
  Print only your pnpm store path
- `<path>`
  Optional path to a project root, `node_modules` folder, or `.pnpm` dir

---

## Examples

1. **Measure current project**

   ```bash
   cd ~/Projects/my-app
   measurepnpm
   ```

2. **Only show your pnpm store location**

   ```bash
   measurepnpm --store
   # Pnpm store path: /Users/you/Library/pnpm/store/v10
   ```

3. **Point at a nested folder**

   ```bash
   measurepnpm ~/some/other/project
   ```

---

## Sample Output

<details>
<summary>Click to expand</summary>

```
Scanning packages... DONE                           ✓ 519 / 797
SIZE      PACKAGE
--------  ----------------------
 48K      safe-array-concat
 16K      is-extglob
 44K      ci-info
728K      web-vitals
...
444.2M    TOTAL

> Store path: /Users/you/Library/pnpm/store/v10
```

- **Live line** shows package name in white, spinner & counts in colour
- **Table** neatly aligns size & package columns
- **TOTAL** is formatted as K/M/G automatically

</details>

---

## Customization

- Tweak colours by editing the ANSI variables at the top of `measurepnpm.zsh`
- Adjust maximum depth of search in the `find` command if you have nonstandard layouts

---

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).
See [LICENSE](./LICENSE) for full text.
