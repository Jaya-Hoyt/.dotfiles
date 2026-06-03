# Print and graph with a preceeding newline
function hxln
    printf '\n' && hg xl --color always
end

abbr hml 'hmail -t %'

abbr hab 'hg absorb'

abbr hfu 'hg fixup -r'
abbr hfue --set-cursor 'hg fixup -r %; hg evolve'
abbr hfuc 'hg fixup --continue'
abbr hfua 'hg fixup --abort'

abbr ha 'hg add'
abbr haa 'hg add .'

abbr har 'hg addremove'
abbr harc 'hg addremove; hg commit'
abbr harcd 'hg addremove; hg commit --addremove --message "Update personal g3docs"; hg fix; hg upload chain; sub; hg sync'
abbr harcs 'hg addremove; hg commit --addremove --message "Update personal scripts"; hg fix; hg upload chain; sub; hg sync'

abbr ham 'hg amend'
abbr hae 'hg amend; hg evolve'
abbr haex 'hg amend; hg export'
abbr haucpsh 'hg amend; hg upload chain; presub && hml'

abbr hdp 'hg drop --prune'

abbr hc 'hg commit'
abbr hca 'hg commit --amend'
abbr hcm --set-cursor 'hg commit --message "%"'

abbr hct 'hg continue'

abbr hd 'hg diff | delta --side-by-side'
abbr hdn 'hg diff % | nvim'

abbr hev 'hg evolve'
abbr heva 'hg evolve --abort'
abbr hevc 'hg evolve --continue'

abbr hex --set-cursor 'hg export % | delta --side-by-side'

abbr hf 'hg fix'

# hg all
abbr haa 'fixts; hg fix; fixbuild; hg amend; hg evolve'
abbr hauc 'fixts; hg fix; fixbuild; hg amend; hg upload chain; hg evolve'
abbr haps 'fixts; hg fix; fixbuild; hg amend; hg upload chain; hg evolve; presub'
abbr haml 'fixts; hg fix; fixbuild; hg amend; hg upload chain; hg evolve; presub; hmail'

abbr hhe 'hg histedit'
abbr hhea 'hg histedit --abort'
abbr hhec 'hg histedit --continue'

abbr hls 'hg l --stat --noninteractive'
abbr hlscl 'hg l | string match "*$USER cl/*" | string collect | read x; echo $x'

abbr hne 'hg next'
abbr hnee 'hg next && hg next'
abbr hneee 'hg next && hg next && hg next'
abbr hneeee 'hg next && hg next && hg next && hg next'
abbr hpr 'hg prev'
abbr hprr 'hg prev && hg prev'
abbr hprrr 'hg prev && hg prev && hg prev'
abbr hprrrr 'hg prev && hg prev && hg prev && hg prev'

abbr hrb 'hg rebase --color always'
abbr hrba 'hg rebase --color always --abort'
abbr hrbc 'hg rebase --color always --continue'
# hrbt: Rebase FROM current commit TO destination
abbr hrbt 'hg rebase --color always -s . -d'
# hrbt: Rebase FROM current commit TO base of the commit chain
abbr hrbtb 'hg rebase --color always -s . -d p4base'
# hrbbt: Rebase current BRANCH (calculated from base) TO destination
abbr hrbbt 'hg rebase --color always -b . -d'
# hrbf: Rebase FROM source commit TO current commit
abbr hrbf 'hg rebase --color always -d . -s'
# hrbbf: Rebase source BRANCH (calculated from base) FROM source TO current commit
abbr hrbbf 'hg rebase --color always -d . -b'

abbr hma 'hg resolve --mark --all'

abbr hr 'hg revert'
abbr hra 'hg revert --all'

abbr hsh 'hg shelve'

abbr hsp 'hg split'

abbr hs 'hg status --color always && hxln'
abbr hsn 'hg status --no-status --color false --noninteractive'
abbr hsm 'hg status | perl -lane \'print $1 if /^M (.*)/\''
abbr hss '{
hg status -n --change . --config commands.status.relative=yes;
hg status -amrun        --config commands.status.relative=yes;
} | sort -u'

abbr hsb 'hg submit'

abbr hsy 'hg sync'

abbr hucnk 'hg uncommit --no-keep'

abbr hush 'hg unshelve'
abbr hushc 'hg unshelve --continue'
abbr husha 'hg unshelve --abort'

abbr hup 'hg update'
abbr hupt 'hg update tip'

abbr huc 'hg upload chain'
abbr hut 'hg upload tree'

abbr hcld 'hg cls-drop --prune'

abbr hxl 'hg xl'

abbr hbk 'hg bookmark'
abbr hbkd 'hg bookmark --delete'
abbr hbkda 'hg bookmark -l | \
string split \' \' --no-empty --fields 1 | \
rush \'hg bookmark --delete {}\''

abbr hpa --position anywhere 'hg patch --adopt-own-cls'
