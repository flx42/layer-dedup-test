#!/bin/bash

set -eu

list_repository() {
    local repository="$1"
    
    local token=$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repository}:pull" | jq -r '.token')
    local tags=$(curl -fsSL -H "Authorization: Bearer ${token}" "https://index.docker.io/v2/${repository}/tags/list" | jq -r '.tags[]')

    for tag in ${tags}; do
	echo "${repository}:${tag}"
    done
}

rm -f tags.list
while read -r repo; do
    list_repository "${repo}" >> tags.list
done < repos.list

parallel --retries 3 --arg-file tags.list -q docker pull "{}" || true

systemctl stop docker
