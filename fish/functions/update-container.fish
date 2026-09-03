function update-container --description "Update a digest-pinned Compose container"
    if test (count $argv) -ne 1
        echo "error: usage: update-container <container-name>" >&2
        return 2
    end

    if not type -q yq
        echo "error: yq v4 is required" >&2
        return 1
    end

    set -l container "$argv[1]"

    if not docker container inspect "$container" >/dev/null 2>&1
        echo "error: container '$container' does not exist" >&2
        return 1
    end

    set -l service (docker inspect --format \
        '{{ index .Config.Labels "com.docker.compose.service" }}' \
        "$container" 2>/dev/null)

    set -l project (docker inspect --format \
        '{{ index .Config.Labels "com.docker.compose.project" }}' \
        "$container" 2>/dev/null)

    set -l working_dir (docker inspect --format \
        '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' \
        "$container" 2>/dev/null)

    set -l files_label (docker inspect --format \
        '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' \
        "$container" 2>/dev/null)

    if test -z "$service"; or test "$service" = "<no value>"
        echo "error: '$container' is not managed by Docker Compose" >&2
        return 1
    end

    if test -z "$project"; or test "$project" = "<no value>"
        echo "error: Compose project label is missing" >&2
        return 1
    end

    if test -z "$files_label"; or test "$files_label" = "<no value>"
        echo "error: Compose configuration-file label is missing" >&2
        return 1
    end

    set -l compose_args -p "$project"
    set -l root_files

    if test -n "$working_dir"; and test "$working_dir" != "<no value>"
        set -a compose_args --project-directory "$working_dir"
    end

    # Files originally passed to docker compose with -f.
    for file in (string split ',' -- "$files_label")
        set file (string trim -- "$file")

        if not string match -qr '^/' -- "$file"
            if test -z "$working_dir"; or test "$working_dir" = "<no value>"
                echo "error: cannot resolve relative Compose file '$file'" >&2
                return 1
            end

            set file "$working_dir/$file"
        end

        set file (realpath "$file" 2>/dev/null)

        if test -z "$file"; or not test -f "$file"
            echo "error: Compose file not found" >&2
            return 1
        end

        set -a root_files "$file"
        set -a compose_args -f "$file"
    end

    # Search root files and all recursively included Compose files.
    set -l scan_queue $root_files
    set -l scanned_files
    set -l source_file
    set -l old_yaml_image

    while test (count $scan_queue) -gt 0
        set -l file "$scan_queue[1]"
        set -e scan_queue[1]

        if contains -- "$file" $scanned_files
            continue
        end

        set -a scanned_files "$file"

        set -l candidate (
            env SERVICE="$service" yq -r \
                '.services[strenv(SERVICE)].image // ""' \
                "$file" 2>/dev/null
        )

        if test $status -ne 0
            echo "error: failed to read '$file'" >&2
            return 1
        end

        if test -n "$candidate"
            set source_file "$file"
            set old_yaml_image "$candidate"
        end

        set -l included_files (
            yq -r \
                '(.include // [])[] | ((select(tag == "!!str")) // .path)' \
                "$file" 2>/dev/null
        )

        if test $status -ne 0
            echo "error: failed to read includes from '$file'" >&2
            return 1
        end

        for included in $included_files
            if test -z "$included"; or test "$included" = "null"
                continue
            end

            if not string match -qr '^/' -- "$included"
                set included (dirname "$file")/"$included"
            end

            set included (realpath "$included" 2>/dev/null)

            if test -z "$included"; or not test -f "$included"
                echo "error: included Compose file not found" >&2
                return 1
            end

            set -a scan_queue "$included"
        end
    end

    if test -z "$source_file"
        echo "error: no image found for service '$service'" >&2
        return 1
    end

    set -l old_image (
        docker inspect --format '{{.Config.Image}}' \
            "$container" 2>/dev/null
    )

    set -l pull_ref (
        string replace -r \
            '@sha256:[0-9a-fA-F]{64}$' '' -- "$old_image"
    )

    if test "$pull_ref" = "$old_image"
        echo "error: image is not digest-pinned: $old_image" >&2
        return 1
    end

    # Pull before causing downtime.
    if not docker pull "$pull_ref" >/dev/null
        echo "error: failed to pull '$pull_ref'" >&2
        return 1
    end

    set -l repo_digest (
        docker image inspect "$pull_ref" \
            --format '{{index .RepoDigests 0}}' 2>/dev/null
    )

    if test $status -ne 0; or test -z "$repo_digest"
        echo "error: could not determine the new image digest" >&2
        return 1
    end

    set -l new_hash (
        string match -r \
            'sha256:[0-9a-fA-F]{64}$' -- "$repo_digest"
    )

    if test -z "$new_hash"
        echo "error: invalid repository digest: $repo_digest" >&2
        return 1
    end

    set -l new_image "$pull_ref@$new_hash"

    if not env SERVICE="$service" NEW_IMAGE="$new_image" yq -i \
        '.services[strenv(SERVICE)].image = strenv(NEW_IMAGE)' \
        "$source_file"

        echo "error: failed to update '$source_file'" >&2
        return 1
    end

    if not docker compose $compose_args config --quiet
        env SERVICE="$service" OLD_IMAGE="$old_yaml_image" yq -i \
            '.services[strenv(SERVICE)].image = strenv(OLD_IMAGE)' \
            "$source_file"

        echo "error: invalid Compose configuration; old pin restored" >&2
        return 1
    end

    if not docker compose $compose_args down >/dev/null
        env SERVICE="$service" OLD_IMAGE="$old_yaml_image" yq -i \
            '.services[strenv(SERVICE)].image = strenv(OLD_IMAGE)' \
            "$source_file"

        docker compose $compose_args up -d >/dev/null
        echo "error: compose down failed; old pin restored" >&2
        return 1
    end

    if not docker compose $compose_args up -d >/dev/null
        env SERVICE="$service" OLD_IMAGE="$old_yaml_image" yq -i \
            '.services[strenv(SERVICE)].image = strenv(OLD_IMAGE)' \
            "$source_file"

        docker compose $compose_args up -d >/dev/null
        echo "error: deployment failed; rollback attempted" >&2
        return 1
    end

    echo "$new_hash"
end
