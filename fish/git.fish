abbr gt 'viddy --no-title \
--interval 1s \
\'cd . && ([ $(( $(date +%s) % 20 )) -eq 0 ] && git fetch --quiet >/dev/null 2>&1 &); git -c color.status=always status -s && printf "\n" && git log --graph --all --pretty=format:"%C(bold)%h%Creset%C(auto)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset" --abbrev-commit --date=relative --color=always -n 10\''

# Erase default gs abbreviation to allow ~/.local/bin/gs binary to run
abbr --erase gs
