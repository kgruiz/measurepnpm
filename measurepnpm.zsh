# -----------------------------------------------------------------------------
# measurepnpm
# -----------------------------------------------------------------------------
#
# Description:
#   Lists each pnpm package under node_modules/.pnpm with its actual on-disk
#   size taken from the pnpm store. Supports:
#     • printing the store path only (-s | --store)
#     • passing an explicit project / node_modules / .pnpm path
#     • showing a TOTAL line at the bottom
#     • a single-line live progress indicator
#
# Usage:
#   measurepnpm [ -h | --help ] [ -s | --store ] [ <path> ]
#
# -----------------------------------------------------------------------------

function measurepnpm() {
  # colour palette
  local RED=$'\e[0;31m'
  local GREEN=$'\e[0;32m'
  local YELLOW=$'\e[0;33m'
  local WHITE=$'\e[0;37m'
  local NC=$'\e[0m'

  ##########################################################################
  # parse flags
  local showStore=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat <<EOF
${YELLOW}Usage:${NC} measurepnpm [ -h | --help ] [ -s | --store ] [ <path> ]

${YELLOW}Description:${NC}
  Lists pnpm packages and their true sizes from the store, sorted.

${YELLOW}Options:${NC}
  -h, --help      Show this help message and exit
  -s, --store     Print pnpm store path only

${YELLOW}Argument:${NC}
  <path>          Project root • node_modules • .pnpm dir (optional)
EOF
        return 0 ;;
      -s|--store)
        showStore=true
        shift && continue ;;
      *)
        break ;;
    esac
    shift
  done

  ##########################################################################
  # store-only early exit
  local STORE
  STORE=$(pnpm store path)
  if [[ $showStore == true ]]; then
    print -r -- "${GREEN}Pnpm store path:${NC} $STORE"
    return 0
  fi

  ##########################################################################
  # resolve node_modules root
  local base="$1" nmDir
  if [[ -n $base ]]; then
    if   [[ -d $base/.pnpm               ]]; then nmDir=$base
    elif [[ ${base##*/} == .pnpm && -d $(dirname "$base")/.pnpm ]]; then nmDir=$(dirname "$base")
    elif [[ -d $base/node_modules/.pnpm  ]]; then nmDir=$base/node_modules
    else
      print -r -- "${RED}Error:${NC} '$base' is not project-root / node_modules / .pnpm dir."
      return 1
    fi
  else
    nmDir=node_modules
  fi

  if [[ ! -d $nmDir/.pnpm ]]; then
    print -r -- "${RED}Error:${NC} no .pnpm directory found under '$nmDir'."
    return 1
  fi

  ##########################################################################
  # gather candidate dirs (fast) and pre-count
  local -a pkgdirs
  pkgdirs=( ${(f)"$(find "$nmDir/.pnpm" -maxdepth 3 -type d -path '*/node_modules/*')"} )
  local total=${#pkgdirs}

  ##########################################################################
  # data structures
  local -a lines=()
  local -A seen
  local sum_kb=0 count=0
  local -a sp=( '|' '/' '-' '\\' )
  local size_k size_h

  ##########################################################################
  # live progress
  printf "${YELLOW}Scanning packages...%s" "$NC"

  for pkgdir in "${pkgdirs[@]}"; do
    local pkg=${pkgdir:t}
    [[ $pkg == @* ]] && continue

    local realdir=${seen[$pkgdir]}
    if [[ -z $realdir ]]; then
      realdir=$(realpath "$pkgdir")
      seen[$realdir]=1

      size_k=$(du -sk "$realdir" 2>/dev/null | cut -f1)
      size_h=$(du -sh "$realdir" 2>/dev/null | cut -f1)

      (( sum_kb += size_k ))
      # store *plain* size + pkg
      lines+=("${size_h}  ${pkg}")
    fi

    (( count++ ))
    local spinChar=${sp[$(( (count-1) % 4 + 1 ))]}

    # clear line and update progress, with pkg name in white
    printf "\r\033[K${YELLOW}Scanning packages... ${WHITE}%-30.30s ${YELLOW}%s %d / %d${NC}" \
           "$pkg" "$spinChar" "$count" "$total"
  done

  # clear line and final status
  printf "\r\033[K${GREEN}Scanning packages... %-30s ✓ %d / %d${NC}\n" \
         "DONE" "$count" "$total"

  ##########################################################################
  # output results in two neat columns
  printf "%s%-8s%s  %s\n" "$YELLOW" "SIZE" "$NC" "PACKAGE"
  echo "--------  ----------------------"
  # sort raw lines, then colour *outside* the width format
  printf '%s\n' "${lines[@]}" | sort -h | while IFS= read -r line; do
    local size_field=${line%%  *}
    local pkg_field=${line#*  }
    printf "${GREEN}%-8s${NC}  %s\n" "$size_field" "$pkg_field"
  done

  ##########################################################################
  # human-readable total
  local total_h
  if   (( sum_kb < 1024    )); then total_h="${sum_kb}K"
  elif (( sum_kb < 1048576  )); then total_h=$(awk -v kb="$sum_kb" 'BEGIN{printf "%.1fM", kb/1024}')
  else                                total_h=$(awk -v kb="$sum_kb" 'BEGIN{printf "%.1fG", kb/1024/1024}')
  fi
  printf "%s%-8s%s  TOTAL\n" "$YELLOW" "$total_h" "$NC"

  # footer
  print -r -- "${GREEN}> Store path:${NC} $STORE"
}
