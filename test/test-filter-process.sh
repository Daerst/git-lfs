#!/usr/bin/env bash

. "test/testlib.sh"

if [ "$GIT_LFS_USE_LEGACY_FILTER" == "1" ]; then
  echo "skip: $0 (filter process disabled)"
  exit
fi

ensure_git_version_isnt $VERSION_LOWER "2.10.0"

begin_test "filter process: checking out a branch"
(
  set -e

  reponame="filter_process_checkout"
  setup_remote_repo "$reponame"
  clone_repo "$reponame" repo

  git lfs track "*.dat"
  git add .gitattributes
  git commit -m "initial commit"

  contents_a="contents (a)"
  contents_a_oid="$(calc_oid $contents_a)"
  printf "$contents_a" > a.dat

  git add a.dat
  git commit -m "add a.dat"

  git checkout -b b

  contents_b="contents (b)"
  contents_b_oid="$(calc_oid $contents_b)"
  printf "$contents_b" > b.dat

  git add b.dat
  git commit -m "add b.dat"

  git push origin --all

  pushd ..
    git \
      -c "filter.lfs.process=git-lfs filter" \
      -c "filter.lfs.clean="\
      -c "filter.lfs.smudge=" \
      -c "filter.lfs.required=true" \
      clone "$GITSERVER/$reponame" "$reponame-assert"

    cd "$reponame-assert"

    # Assert that we are on the "master" branch, and have a.dat
    [ "master" = "$(git rev-parse --abbrev-ref HEAD)" ]
    [ "$contents_a" = "$(cat a.dat)" ]

    git checkout b

    # Assert that we are on the "b" branch, and have b.dat
    [ "b" = "$(git rev-parse --abbrev-ref HEAD)" ]
    [ "$contents_b" = "$(cat b.dat)" ]
  popd
)
end_test
