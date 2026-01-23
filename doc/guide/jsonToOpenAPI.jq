.["$defs"]|{components:{schemas:.}} |
 walk(if type == "object" and has("$comment") then del(.["$comment"]) else . end)|
 (.. | objects| select(has("$ref")) ).["$ref"] |= sub("^[^#]+#/\\$defs";"#/components/schemas")