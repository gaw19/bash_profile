#!/bin/bash

[ -n "$VERSION" ] && export VERSION && return

# detect by any tag
TAG=$(git tag -l --points-at HEAD)
# we might have multiple tags at the same commit, will pick only 1

for i in ${TAG[@]}; do
    # only use tag if tag is start with v
    [[ $i =~ ^v ]] && VERSION=${i:1}
done
[ -n "$VERSION" ] && export VERSION && return

IFS=$' '
# either tag or branch to determine base vesion
START_TAG=`git tag | grep start- | sort -Vr | head -n 1`
[ -n START_TAG ] && BASE_VERSION=(`echo ${START_TAG#start-} | tr '.' ' '`) && REV=$START_TAG
BRANCH=`git rev-parse --abbrev-ref HEAD`
[[ $BRANCH =~ release ]] &&
    BASE_VERSION=(`echo ${BRANCH#release-} | tr '.' ' '`) &&
    REV=(`git rev-list --boundary $BRANCH...develop | grep ^- | cut -c2-`)

# at least require two versions
V_MAJOR=${BASE_VERSION[0]}
V_MINOR=${BASE_VERSION[1]}
V_PATCH=${BASE_VERSION[2]-0}
V_BUILD=${BASE_VERSION[3]-0}

IFS=$'\n'
COMMITS=(`git log --oneline --reverse --no-merges HEAD...$REV --format="%s"`)
for subject in ${COMMITS[@]}; do
  case $subject in 
    feat:*)
      let "V_MINOR++"
      let V_PATCH=0
      let V_BUILD=0
      ;;
    fix:*)
      let "V_PATCH++"
      let V_BUILD=0
      ;;
    *)
      let "V_BUILD++"
      ;;
  esac
done
VERSION=$V_MAJOR.$V_MINOR.$V_PATCH.$V_BUILD

[ -n "$VERSION" ] && export VERSION && return
