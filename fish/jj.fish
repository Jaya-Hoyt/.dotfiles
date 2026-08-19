# ==============================================================================
# jj.fish - Jujutsu (jj) abbreviations for Google3 / Piper workflows
# Translated, adapted, and extended from hg.fish (Fig/Mercurial)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Visualization & Graph Log
# ------------------------------------------------------------------------------
# Print graph log with a preceding newline (replaces hxln)
function jxln
    printf '\n' && jj log --color always
end

abbr jxl jxln
abbr jl 'jj log'
abbr jla 'jj log -r "all()"'
abbr jlm 'jj log -r "mine()"'
abbr jlu 'jj log -r "mutable()"'
abbr jln 'jj log --no-graph'
abbr jls 'jj log --stat'

# Extract current change's CL (e.g. cl/123456) and copy to clipboard
abbr jcl 'jj log -r \'@ | @-\' --no-pager --color=never | perl -nE \'if (m{\\b(cl/\\d+)\\b}) { print $1; exit; }\' | tty-copy -n'

# Live status + graph dashboard watcher (replaces ft)
abbr jt 'cd . \
&& viddy --no-title --interval 1s \
"cd \"$PWD\" \
        && jj diff -s --color always \\
        && printf \'\n\' \\
        && jj log --ignore-working-copy --color always"'

# ------------------------------------------------------------------------------
# 2. Status & Diffs
# ------------------------------------------------------------------------------
# Status with smart log (replaces hs, hsn)
abbr jst 'jj status --color always && jxln'

# Diff with side-by-side delta (replaces hd, hdn, hdi) - defaults to @ (working copy)
abbr jd 'jj diff --git | delta --side-by-side'
abbr jdp 'jj diff -r @- --git | delta --side-by-side'
abbr jdpp 'jj diff -r @-- --git | delta --side-by-side'
abbr jdr --set-cursor 'jj diff -r % --git | delta --side-by-side'

# Inline diff with Delta inline diff
abbr jdi 'jj diff --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdip 'jj diff -r @- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdpi 'jj diff -r @- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdipp 'jj diff -r @-- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdppi 'jj diff -r @-- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdir --set-cursor 'jj diff -r % --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jdri --set-cursor 'jj diff -r % --git | DELTA_FEATURES=tokyonight-storm delta'

# Diff stat
abbr jds 'jj diff --stat'
abbr jdsp 'jj diff -r @- --stat'
abbr jdspp 'jj diff -r @-- --stat'
abbr jdsr --set-cursor 'jj diff -r % --stat'

# Raw git diff
abbr jgd 'jj diff --git'
abbr jgdp 'jj diff -r @- --git'
abbr jgdpp 'jj diff -r @-- --git'
abbr jgdr --set-cursor 'jj diff -r % --git'

# List modified files / status filenames (replaces hsm, hss)
abbr jdn 'jj diff --name-only'
abbr jdnp 'jj diff -r @- --name-only'
abbr jdnpp 'jj diff -r @-- --name-only'
abbr jdnr --set-cursor 'jj diff -r % --name-only'

# Show / Export specific revision (replaces hex, hexi) - defaults to @ (working copy)
abbr jsh 'jj show --git | delta --side-by-side'
abbr jshi 'jj show --git | DELTA_FEATURES=tokyonight-storm delta'

# Show / Export parent (@-) and grandparent (@--)
abbr jshp 'jj show -r @- --git | delta --side-by-side'
abbr jship 'jj show -r @- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jshpi 'jj show -r @- --git | DELTA_FEATURES=tokyonight-storm delta'

abbr jshpp 'jj show -r @-- --git | delta --side-by-side'
abbr jshipp 'jj show -r @-- --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jshppi 'jj show -r @-- --git | DELTA_FEATURES=tokyonight-storm delta'

# Show parameterized by revision
abbr jshr --set-cursor 'jj show -r % --git | delta --side-by-side'
abbr jshir --set-cursor 'jj show -r % --git | DELTA_FEATURES=tokyonight-storm delta'
abbr jshri --set-cursor 'jj show -r % --git | DELTA_FEATURES=tokyonight-storm delta'

# Interdiff - compare changes across versions/snapshots
abbr jid --set-cursor 'jj interdiff --from % --to @'
abbr jidp --set-cursor 'jj interdiff --from % --to @-'

# ------------------------------------------------------------------------------
# 3. Working Copy, Commits, & Descriptions
# Note: In jj, edits to working-copy files are auto-amended into @ in real time.
# ------------------------------------------------------------------------------
# jj commit: sets description and immediately opens a fresh empty commit on top (matches gc/gcm)
abbr jc 'jj commit'
abbr jcm --set-cursor 'jj commit -m "%"'

# jj new: start a new empty working-copy commit
abbr jn 'jj new'
abbr jnm 'jj new main'
abbr jnb 'jj new p4base'
abbr jnr --set-cursor 'jj new %'
abbr jcb --set-cursor 'jj new master -m "%"'
abbr jcob --set-cursor 'jj new master -m "%"'

# jj edit / checkout: switch working copy to an existing commit (matches gco/gcom)
abbr jed --set-cursor 'jj edit %'
abbr jedm 'jj edit main'
abbr jedb 'jj edit p4base'
abbr jedp 'jj edit @-'
abbr jedpp 'jj edit @--'

# jj describe: edit commit message in place (replaces hca/describe) - defaults to @ (working copy)
abbr jdesc 'jj describe'
abbr jdescm --set-cursor 'jj describe -m "%"'
abbr jdescp 'jj describe -r @-'
abbr jdescpm --set-cursor 'jj describe -r @- -m "%"'
abbr jdescpp 'jj describe -r @--'
abbr jdescppm --set-cursor 'jj describe -r @-- -m "%"'
abbr jdescr --set-cursor 'jj describe -r %'

# ------------------------------------------------------------------------------
# 4. History Modification, Squash & Fixup
# Note: In jj, evolving descendants is 100% automatic; no 'hg evolve' needed!
# ------------------------------------------------------------------------------
# jj absorb: auto-distribute working copy changes into the commits that touched those lines
abbr jab 'jj absorb'

# Fold / Squash changes (matches gcaa/gcamd amend and hfu/ham/hca)
# -u (--use-destination-message) keeps the target's commit description intact
abbr jsq 'jj squash'
abbr jsqu 'jj squash -u'

abbr jsqp 'jj squash -r @-'
abbr jsqpp 'jj squash -r @--'

# Parallelize linear commits into siblings
abbr jpar 'jj parallelize'

# Interactive arrangement & diff editing - defaults to @ (working copy)
abbr jarr 'jj arrange'
abbr jdedit 'jj diffedit'
abbr jdeditp 'jj diffedit -r @-'
abbr jdeditpp 'jj diffedit -r @--'
abbr jdeditr --set-cursor 'jj diffedit -r %'

abbr jevo 'jj evolog -p'
abbr jevop 'jj evolog -r @- -p'
abbr jevopp 'jj evolog -r @-- -p'
abbr jevologp 'jj evolog -r @- -p'
abbr jevologpp 'jj evolog -r @-- -p'

# Split commits (replaces hsp) - defaults to @ (working copy)
abbr jsp 'jj split'
abbr jspp 'jj split -r @-'
abbr jsppp 'jj split -r @--'
abbr jspr --set-cursor 'jj split -r %'
abbr jspar --set-cursor 'jj split --parallel -m "%"'

# ------------------------------------------------------------------------------
# 5. Operation Log & Undo (Replaces abort/continue workflows)
# Note: jj records all operations. Use undo to roll back mistakes cleanly.
# ------------------------------------------------------------------------------
abbr jun 'jj undo'
abbr jred 'jj redo'
abbr jop 'jj op log'

# ------------------------------------------------------------------------------
# 6. Navigation (Next / Prev)
# Note: jj next/prev support numeric count arguments and --edit directly!
# ------------------------------------------------------------------------------
abbr jne 'jj next'
abbr jnee 'jj next 2'
abbr jneee 'jj next 3'
abbr jneeee 'jj next 4'

abbr jpr 'jj prev'
abbr jprr 'jj prev 2'
abbr jprrr 'jj prev 3'
abbr jprrrr 'jj prev 4'

# ------------------------------------------------------------------------------
# 7. Rebase Operations
# ------------------------------------------------------------------------------
abbr jrb 'jj rebase'
# Rebase current commit + descendants TO destination (defaults to @)
abbr jrbt --set-cursor 'jj rebase -s @ -d %'
abbr jrbtp --set-cursor 'jj rebase -s @- -d %'
# Rebase current commit TO p4base, main, or master (matches grm)
abbr jrbtb 'jj rebase -s @ -d p4base'
abbr jrbtbp 'jj rebase -s @- -d p4base'

abbr jrbtm 'jj rebase -s @ -d main'
abbr jrbtmp 'jj rebase -s @- -d main'

abbr jrbtms 'jj rebase -s @ -d master'
abbr jrbtmsp 'jj rebase -s @- -d master'

abbr jrbo 'jj rebase -s @ -d master@origin'
abbr jrbop 'jj rebase -s @- -d master@origin'

# Rebase entire branch/chain TO destination
abbr jrbbt --set-cursor 'jj rebase -b @ -d %'
abbr jrbbtp --set-cursor 'jj rebase -b @- -d %'

# Rebase source commit TO current commit
abbr jrbf --set-cursor 'jj rebase -s % -d @'
abbr jrbfp --set-cursor 'jj rebase -s % -d @-'

# Rebase source branch TO current commit
abbr jrbbf --set-cursor 'jj rebase -b % -d @'
abbr jrbbfp --set-cursor 'jj rebase -b % -d @-'

# ------------------------------------------------------------------------------
# 8. Restore & Abandon (Replaces hg revert / drop)
# ------------------------------------------------------------------------------
# Restore file(s) in working copy (replaces hr)
abbr jr --set-cursor 'jj restore %'
# Restore all modified files in working copy (replaces hra)
abbr jra 'jj restore'

# Restore/reverse changes introduced in commit (defaults to @)
abbr jrc 'jj restore -c @'
abbr jrcp 'jj restore -c @-'
abbr jrcpp 'jj restore -c @--'
abbr jrcr --set-cursor 'jj restore -c %'

# Discard/Abandon commit or specific revision (replaces hdp) - defaults to @ (working copy)
abbr jabd 'jj abandon @'
abbr jabdp 'jj abandon @-'
abbr jabdpp 'jj abandon @--'
abbr jabdr --set-cursor 'jj abandon %'
abbr jabr --set-cursor 'jj abandon %'

# ------------------------------------------------------------------------------
# 9. Conflict Resolution
# Note: Removing conflict markers from files auto-resolves them in jj.
# ------------------------------------------------------------------------------
abbr jres 'jj resolve'
abbr jresp 'jj resolve -r @-'
abbr jrespp 'jj resolve -r @--'
abbr jresr --set-cursor 'jj resolve -r %'

abbr jrl 'jj resolve --list'
abbr jrlp 'jj resolve -r @- --list'
abbr jrlpp 'jj resolve -r @-- --list'
abbr jrlr --set-cursor 'jj resolve -r % --list'

abbr jro --set-cursor 'jj resolve --tool :ours %'
abbr jrop --set-cursor 'jj resolve -r @- --tool :ours %'
abbr jropp --set-cursor 'jj resolve -r @-- --tool :ours %'
abbr jror --set-cursor 'jj resolve -r % --tool :ours'

abbr jrt --set-cursor 'jj resolve --tool :theirs %'
abbr jrtp --set-cursor 'jj resolve -r @- --tool :theirs %'
abbr jrtpp --set-cursor 'jj resolve -r @-- --tool :theirs %'
abbr jrtr --set-cursor 'jj resolve -r % --tool :theirs'

# ------------------------------------------------------------------------------
# 10. Code Formatting & Composite Workflows
# ------------------------------------------------------------------------------
# Format changed files - defaults to @ (working copy)
abbr jfix 'jj fix -s @'
abbr jfixp 'jj fix -s @-'
abbr jfixpp 'jj fix -s @--'
abbr jfixr --set-cursor 'jj fix -s %'

# ------------------------------------------------------------------------------
# 11. Critique & Piper Lifecycle (Upload, Presubmit, Mail, Submit, Sync, Patch)
# ------------------------------------------------------------------------------
# Upload CLs to Critique (replaces huc, hut) - defaults to @
abbr jpu 'jj piper upload'
abbr jpup 'jj piper upload -r @-'
abbr jpupp 'jj piper upload -r @--'
abbr jpua 'jj piper upload --all'
abbr jpue 'jj piper upload --exported'
abbr jpur --set-cursor 'jj piper upload -r %'

# Presubmit - defaults to @ (working copy)
abbr jpps 'jj piper presubmit'
abbr jppsd 'jj piper presubmit --detach'
abbr jppsp 'jj piper presubmit -r @-'
abbr jppsdp 'jj piper presubmit -r @- --detach'
abbr jppspp 'jj piper presubmit -r @--'
abbr jppsr --set-cursor 'jj piper presubmit -r %'
abbr jppsrd --set-cursor 'jj piper presubmit -r % --detach'

# Mail (replaces hml) - defaults to @ (working copy)
abbr jpml 'jj piper mail'
abbr jpmlf 'jj piper mail --find-reviewers'
abbr jpmlr 'jj piper mail --remail'
abbr jpmlpr 'jj piper mail --reviewers $PRIMARY_REVIEWER'

abbr jpmlp 'jj piper mail -r @-'
abbr jpmlpf 'jj piper mail -r @- --find-reviewers'
abbr jpmlrp 'jj piper mail -r @- --remail'
abbr jpmlprp 'jj piper mail -r @- --reviewers $PRIMARY_REVIEWER'

# Submit (replaces hsb, sub) - defaults to @ (working copy)
abbr jps 'jj piper submit'
abbr jpsd 'jj piper submit --detach'
abbr jpsp 'jj piper submit -r @-'
abbr jpsdp 'jj piper submit -r @- --detach'
abbr jpspp 'jj piper submit -r @--'
abbr jpsr --set-cursor 'jj piper submit -r %'
abbr jpsrd --set-cursor 'jj piper submit -r % --detach'

# Sync (replaces hsy)
abbr jpsy 'jj piper sync'
abbr jpsya 'jj piper sync --all'

# Drop CL from Critique/Piper (replaces hcld)
abbr jpcld --set-cursor 'jj piper cls drop --skip-confirmation %'
abbr jpcldk --set-cursor 'jj piper cls drop --skip-confirmation --keep-local %'

# Import / Patch CL from Piper (replaces hpa)
abbr jppa --position anywhere 'jj piper patch'
abbr jppad --position anywhere --set-cursor 'jj piper patch --duplicate %'
abbr jppan --position anywhere --set-cursor 'jj piper patch --no-adopt %'
abbr jppas --position anywhere --set-cursor 'jj piper patch --squash-diffbases %'

# Piper Linter Findings - defaults to @ (working copy)
abbr jpli 'jj piper lint'
abbr jplip 'jj piper lint -r @-'
abbr jplipp 'jj piper lint -r @--'
abbr jplir --set-cursor 'jj piper lint -r %'

# ------------------------------------------------------------------------------
# 12. Bookmarks (Matches Git Branch gb / gba / gbd / gbm / gbt)
# ------------------------------------------------------------------------------
# Primary Git-matching abbreviations (gb -> jb) - defaults to @ (working copy)
abbr jb 'jj bookmark'
abbr jbl 'jj bookmark list'
abbr jba 'jj bookmark advance'
abbr jbla 'jj bookmark list --all'
abbr jtug 'jj bookmark advance'

abbr jbs --set-cursor 'jj bookmark set % -r @'
abbr jbc --set-cursor 'jj bookmark create % -r @'

abbr jbsp --set-cursor 'jj bookmark set % -r @-'
abbr jbcp --set-cursor 'jj bookmark create % -r @-'

abbr jbspp --set-cursor 'jj bookmark set % -r @--'
abbr jbcpp --set-cursor 'jj bookmark create % -r @--'

abbr jbr --set-cursor 'jj bookmark rename %'
abbr jbd --set-cursor 'jj bookmark delete %'
abbr jbdel --set-cursor 'jj bookmark delete %'
abbr jbt --set-cursor 'jj bookmark track % --remote origin'
abbr jbu --set-cursor 'jj bookmark untrack % --remote origin'

abbr jbkda 'jj bookmark list -T "if(remote, \"\", name ++ \"\n\")" | while read -l b; test -n "$b" && jj bookmark delete "$b"; end'

# ------------------------------------------------------------------------------
# 13. File Operations (History Preserving)
# ------------------------------------------------------------------------------
abbr jpmv --set-cursor 'jj piper rename %'
abbr jpcp --set-cursor 'jj piper copy %'
abbr jpmva --set-cursor 'jj piper rename --after %'
abbr jpcpa --set-cursor 'jj piper copy --after %'

abbr jft --set-cursor 'jj file track %'
abbr jfut --set-cursor 'jj file untrack %'

# ------------------------------------------------------------------------------
# 14. CitC Workspace Navigation & Management
# ------------------------------------------------------------------------------
abbr jpgoto --set-cursor 'cd (jj piper jjd %)'
abbr jpmkws --set-cursor 'cd (jj piper jjd -f %)'
abbr jpwsl 'jj piper citc list'
abbr jpwsd --set-cursor 'jj piper citc delete %'

# ------------------------------------------------------------------------------
# 15. Git & GitHub Interoperability
# ------------------------------------------------------------------------------
# Push (Matches gp / gpd / gpp)
abbr jgpush 'jj git push'
abbr jgpa 'jj git push --all'

# Fetch & Pull / Rebase (Matches gf / gl / glr / gpp)
abbr jgf 'jj git fetch'
abbr jgfa 'jj git fetch --all-remotes'

abbr jgl 'jj git fetch && jj rebase -s @ -d master@origin'
abbr jglp 'jj git fetch && jj rebase -s @- -d master@origin'
abbr jglpp 'jj git fetch && jj rebase -s @-- -d master@origin'

abbr jglr --set-cursor 'jj git fetch && jj rebase -s % -d master@origin'

abbr jgpr 'jj git fetch && jj rebase -s @ -d master@origin && jj git push'
abbr jgprp 'jj git fetch && jj rebase -s @- -d master@origin && jj git push'
abbr jgprpp 'jj git fetch && jj rebase -s @-- -d master@origin && jj git push'

# Remotes & Sync
abbr jgr 'jj git remote list'
abbr jgra --set-cursor 'jj git remote add %'

# Commits (Matches gc / gcm)
abbr jgc 'jj commit'
abbr jgcm --set-cursor 'jj commit -m "%"'

# Init & Clone (Matches gcl)
abbr jgco 'jj git init --colocate'
abbr jgcl --set-cursor 'jj git clone %'

# Advance bookmark to current commit (@) and push to GitHub
abbr jgp "jj bookmark move --from 'heads(::@ & bookmarks())' --to @ && jj git push"
abbr jgpp "jj bookmark move --from 'heads(::@- & bookmarks())' --to @- && jj git push"

abbr jbm "jj bookmark move --from 'heads(::@ & bookmarks())' --to @"
abbr jbmp "jj bookmark move --from 'heads(::@- & bookmarks())' --to @-"
abbr jbmpp "jj bookmark move --from 'heads(::@-- & bookmarks())' --to @--"
