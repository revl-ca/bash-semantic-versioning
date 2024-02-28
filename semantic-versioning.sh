#!/usr/bin/env bash

set -eo pipefail

# USAGE: ./semvr [--debug,--print,--stdout,--print-all,--final,--final-all] path1 path2 path3 ...
#
# +----------+----------------------------------------------------------+-------+
# | *        | Anything                                                 | RC    |
# | break    | A breaking change                                        | MAJOR |
# | feat     | A new feature                                            | MINOR |
# | fix      | A bug fix                                                | PATCH |
# | docs     | Documentation only changes                               | PATCH |
# | style    | Changes that do not affect the meaning of the code       | PATCH |
# |          | (white-space, formatting, missing semi-colonsm etc)      |       |
# | refactor | A code change that neither fixes a bug or adds a feature | PATCH |
# | perf     | A code change that improves performance                  | MINOR |
# | test     | Adding missing tests                                     | PATCH |
# | chore    | Changes to the build process or auxiliary tools          | PATCH |
# |          | and libraries such as documentation generation           |       |
# +----------+----------------------------------------------------------+-------|

export PATHS=()
export DEBUG=0
export SEMVER_PRINT=1
export SEMVER_PRINT_ONLY=0
export SEMVER_FINAL=0
export SEMVER_FINAL_ONLY=0

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --debug)
        DEBUG=1;;
      --print | --stdout)
        SEMVER_PRINT=1;;
      --print-all)
        SEMVER_PRINT_ALL=1;;
      --final)
        SEMVER_PRINT=0
        SEMVER_PRINT_ALL=0
        SEMVER_FINAL=1;;
      --final-all)
        SEMVER_FINAL_ALL=1;;
      *)
        PATHS+=("$arg");;
    esac
  done

  if [[ "${#PATHS[@]}" = "0" ]]; then
    PATHS+=(".")
  fi
}

semvr() {
  local PATHS=("$@")
  local PATCH=0
  local MINOR=1
  local MAJOR=0
  local RC=0

  for FOLDER in "${PATHS[@]}"; do

    CURRENT=$(git describe --tags --abbrev=0 2> /dev/null || echo "0.1.0")
    HISTORY=$(git --no-pager log --reverse --oneline "$CURRENT"..HEAD -- "$FOLDER" | awk '{ $1=""; print }' | sed -e 's/^[[:space:]]*//')
    IFS="." read -r MAJOR MINOR PATCH <<< "$CURRENT"

    (( DEBUG )) && echo -e "\e[33m-> Folder\e[0m $FOLDER ($CURRENT)"

    while IFS= read -r MESSAGE; do
      (( DEBUG )) && echo -e "\e[32m-> Commit:\e[0m $MESSAGE"

      if [[ "$MESSAGE" =~ ^break ]]; then
        MAJOR=$((MAJOR+1))
        MINOR=0
        PATCH=0
        RC=0

        (( DEBUG )) && echo -e "\e[33m-->\e[0m Major +1"
      elif [[ "$MESSAGE" =~ ^feat|^perf ]]; then
        MINOR=$((MINOR+1))
        PATCH=0
        RC=0

        (( DEBUG )) && echo -e "\e[33m-->\e[0m Minor +1"
      elif [[ "$MESSAGE" =~ ^fix|^docs|^style|^refactor|^test|^chore ]]; then
        PATCH=$((PATCH+1))
        RC=0

        (( DEBUG )) && echo -e "\e[33m-->\e[0m Patch +1"
      else
        RC=$((RC+1))

        (( DEBUG )) && echo -e "\e[33m-->\e[0m RC +1"
      fi
    done < <(printf '%s\n' "$HISTORY")

    if [[ "$SEMVER_PRINT" = "1" ]]; then
      echo "$MAJOR.$MINOR.$PATCH-$RC"
    elif [[ "$SEMVER_PRINT_ALL" = "1" ]]; then
      echo "$MAJOR.$MINOR.$PATCH $MAJOR.$MINOR.$PATCH-$RC $MAJOR $MINOR $PATCH $RC"
    elif [[ "$SEMVER_FINAL" = "1" ]]; then
      echo "$MAJOR.$MINOR.$PATCH"
    elif [[ "$SEMVER_FINAL_ALL" = "1" ]]; then
      echo "$MAJOR.$MINOR.$PATCH $MAJOR.$MINOR.$PATCH $MAJOR $MINOR $PATCH"
    fi
  done
}

parse_args "$@"
semvr "${PATHS[@]}"
