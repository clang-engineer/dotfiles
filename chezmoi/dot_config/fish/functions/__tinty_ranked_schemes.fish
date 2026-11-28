function __tinty_ranked_schemes
    set -l cache_home "$HOME/.cache"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_home "$XDG_CACHE_HOME"
    end
    set -l cache "$cache_home/tinted-theming/tinty/radar-ranks.json"

    if not test -f "$cache"; or not test -n (find "$cache" -mtime -1 -print 2>/dev/null)
        mkdir -p (dirname "$cache")
        set -l download (mktemp "$cache.XXXXXX")
        if curl -fsSL --connect-timeout 2 --max-time 3 https://clang-engineer.github.io/data/rankings.json \
                | jq -e '.categories[] | select(.id == "developer-color-themes" and (.items | type == "array"))' > "$download"
            mv -f -- "$download" "$cache"
        else
            rm -f -- "$download"
        end
    end

    set -l stars '{}'
    if test -f "$cache"
        # Join families by name; same-name repositories use the highest Stars.
        set stars (jq -c '
            [.items[] | select((.id | type) == "string" and (.stars | type) == "number")
                | {key: (.id | split("/")[-1] | ascii_downcase
                    | sub("[.](nvim|vim)$"; "") | sub("-theme$"; "")
                    | gsub("[^a-z0-9]"; "")), value: .stars}]
            | sort_by(.key) | group_by(.key) | map(max_by(.value)) | from_entries
        ' "$cache" 2>/dev/null)
        or set stars '{}'
    end

    # Prefer centrally generated family matches; retain legacy ranks when unavailable.
    set -l family_cache "$cache_home/tinted-theming/tinty/theme-families.json"
    if not test -f "$family_cache"; or not test -n (find "$family_cache" -mtime -1 -print 2>/dev/null)
        mkdir -p (dirname "$family_cache")
        set -l download (mktemp "$family_cache.XXXXXX")
        if curl -fsSL --connect-timeout 2 --max-time 3 https://clang-engineer.github.io/data/theme-families.json \
                | jq -e 'select(.version == 1 and (.families | type == "object") and (.schemes | type == "object"))' > "$download"
            mv -f -- "$download" "$family_cache"
        else
            rm -f -- "$download"
        end
    end
    set -l families '{}'
    if test -f "$family_cache"
        set families (jq -c '. as $data | .schemes | with_entries(.value = $data.families[.value].stars)' "$family_cache" 2>/dev/null)
        or set families '{}'
    end

    # The JSON ID can omit a variant suffix present in the applyable plain list.
    set -l ids (command tinty list | jq -Rsc 'split("\n") | map(select(length > 0))')
    command tinty list --json | jq -r --argjson ids "$ids" --argjson stars "$stars" --argjson families "$families" '
        def leftpad($width): (" " * ([$width - length, 0] | max)) + .;
        def commas:
            tostring | split("") as $digits
            | [range(0; $digits | length) as $i
                | $digits[$i] + (if (($digits | length) - $i - 1) > 0
                    and ((($digits | length) - $i - 1) % 3) == 0
                    then "," else "" end)]
            | join("");
        def rank($id):
            ($id | sub("^base16-"; "") | split("-")) as $words
            | [range(1; ($words | length) + 1) as $n
                | {key: ($words[:$n] | join("")), next: ($words[$n] // "")}
                | select($stars[.key] != null)]
            | .[-1] // null
            | if . == null or ($stars[.next] != null)
                then 0 else ($stars[.key] // 0) end;
        [.[] | select(.system == "base16") | . as $scheme
            | ($scheme.id as $id
                | if ($ids | index($id)) != null then $id
                  elif ($ids | index($id + "-" + $scheme.variant)) != null
                    then $id + "-" + $scheme.variant
                  else empty end) as $valid_id
            | . + {id: $valid_id, stars: ($families[$valid_id] // rank($valid_id))}]
        | sort_by(-.stars, .id)[]
        | "\(.id)\t\(if .stars > 0 then " " else "  " end)\((if .stars > 0 then (.stars | commas) else "-" end) | leftpad(7))  \(.id | sub("^base16-"; ""))\(if .variant == "light" then "  [light]" else "" end)"
    '
end
