#!/usr/bin/env bash

set -eo pipefail

# USAGE: ./semantic-versioning.sh [--print,--stdout,--file,--tag,--git] path1 path2 path3 ...
#
# +----------+----------------------------------------------------------+-------+
# | *        | Anything                                                 | PATCH |
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
#
# TODO: Support revert ?
# TODO: Support branches ?
# TODO: Support git tags ?
# TODO: Support for other syntax such as: +semver: patch/minor/major

export PATHS=()
export SEMVER_PRINT=0
export SEMVER_FILE=0
export SEMVER_TAG=0

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --print | --stdout)
        SEMVER_PRINT=1;;
      --file)
        SEMVER_FILE=1;;
      --tag | --git)
        SEMVER_TAG=1;;
      *)
        PATHS+=("$arg");;
    esac
  done

  if [[ "${#PATHS[@]}" = "0" ]]; then
    PATHS+=(".")
  fi
}

scan_paths() {
  local PATHS=("$@")

  for FOLDER in "${PATHS[@]}"; do
    local PATCH=0
    local MINOR=0
    local MAJOR=0

    #echo "--> $FOLDER"

    HISTORY=$(git --no-pager log --reverse --oneline -- "$FOLDER" | awk '{ $1=""; print }' | sed -e 's/^[[:space:]]*//')

    while IFS= read -r MESSAGE; do
      #echo "$MESSAGE"

      if [[ "$MESSAGE" =~ ^break ]]; then
        MAJOR=$((MAJOR+1))
        MINOR=0
        PATCH=0
      elif [[ "$MESSAGE" =~ ^feat|^perf ]]; then
        MINOR=$((MINOR+1))
        PATCH=0
      elif [[ "$MESSAGE" =~ ^fix|^docs|^style|^refactor|^test|^chore ]]; then
        PATCH=$((PATCH+1))
      else
        PATCH=$((PATCH+1))
      fi
    done < <(printf '%s\n' "$HISTORY")

    if [[ "$SEMVER_PRINT" = "1" ]]; then
      echo "$FOLDER $MAJOR.$MINOR.$PATCH $MAJOR $MINOR $PATCH"
    #elif [[ "$SEMVER_FILE" = "1" ]]; then
      # TODO
    #elif [[ "$SEMVER_TAG" = "1" ]]; then
      # TODO
    fi
  done
}

parse_args "$@"
scan_paths "${PATHS[@]}"

