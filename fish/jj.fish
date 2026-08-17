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
abbr jstn 'jj status'

# Diff with side-by-side delta (replaces hd, hdn, hdi)
abbr jd 'jj diff --git | delta --side-by-side'
abbr jdp --set-cursor 'jj diff --git @-% | delta --side-by-side'
abbr jdn --set-cursor 'jj diff --git % | nvim'
abbr jdi --set-cursor 'jj diff --git % | DELTA_FEATURES=tokyonight-storm delta'
abbr jdpi --set-cursor 'jj diff --git @-% | DELTA_FEATURES=tokyonight-storm delta'
abbr jds 'jj diff --stat'
abbr jdf 'jj diff --git'
abbr jdr --set-cursor 'jj diff -r % --git | delta --side-by-side'

# List modified files / status filenames (replaces hsm, hss)
abbr jss 'jj diff --name-only'
abbr jsm 'jj diff --name-only'

# Show / Export specific revision (replaces hex, hexi)
abbr jsh --set-cursor 'jj show --git % | delta --side-by-side'
abbr jshi --set-cursor 'jj show --git % | DELTA_FEATURES=tokyonight-storm delta'
abbr jshow --set-cursor 'jj show --git %'

# Show / Export parent commit
abbr jshp --set-cursor 'jj show --git @-% | delta --side-by-side'
abbr jshpi --set-cursor 'jj show --git @-% | DELTA_FEATURES=tokyonight-storm delta'

# Interdiff - compare changes across versions/snapshots (e.g., since last upload)
abbr jid --set-cursor 'jj interdiff --from % --to @'

# ------------------------------------------------------------------------------
# 3. Working Copy, Commits, & Descriptions
# Note: In jj, edits to working-copy files are auto-amended into @ in real time.
# ------------------------------------------------------------------------------
# jj commit: sets description and immediately opens a fresh empty commit on top (matches gc/gcm)
abbr jc 'jj commit'
abbr jcm --set-cursor 'jj commit -m "%"'
abbr jcam --set-cursor 'jj commit -m "%"'

# jj new: start a new empty working-copy commit
abbr jn 'jj new'
abbr jnm 'jj new main'
abbr jnb 'jj new p4base'
abbr jnr --set-cursor 'jj new %'
abbr jcb --set-cursor 'jj new master -m "%"'
abbr jcob --set-cursor 'jj new master -m "%"'
abbr jsth 'jj new'

# jj edit / checkout: switch working copy to an existing commit (matches gco/gcom)
abbr jco --set-cursor 'jj edit %'
abbr jcom 'jj edit master'
abbr jed --set-cursor 'jj edit %'
abbr jedm 'jj edit main'
abbr jedb 'jj edit p4base'
abbr jup --set-cursor 'jj edit %'
abbr jupm 'jj edit main'
abbr jupb 'jj edit p4base'

# jj describe: edit commit message in place (replaces hca/describe)
abbr jdesc 'jj describe'
abbr jdescm --set-cursor 'jj describe -m "%"'

# ------------------------------------------------------------------------------
# 4. History Modification, Squash & Fixup
# Note: In jj, evolving descendants is 100% automatic; no 'hg evolve' needed!
# ------------------------------------------------------------------------------
# jj absorb: auto-distribute working copy changes into the commits that touched those lines
abbr jab 'jj absorb'

# Fold / Squash changes (matches gcaa/gcamd amend and hfu/ham/hca)
# -u (--use-destination-message) keeps the target's commit description intact
abbr jfu --set-cursor 'jj squash --into % -u'
abbr jfup 'jj squash --into @- -u'
abbr jsq 'jj squash'
abbr jsqu --set-cursor 'jj squash --into %'
abbr jsqf --set-cursor 'jj squash --from % --to @'
abbr jam 'jj squash -u'
abbr jca 'jj squash -u'
abbr jcaa 'jj squash -u'
abbr jcamd 'jj squash -u'
abbr jamex 'jj squash -u; jj show --git'

# Parallelize linear commits into siblings
abbr jpar 'jj parallelize'

# Interactive arrangement & diff editing
abbr jarr 'jj arrange'
abbr jdfedit 'jj diffedit'
abbr jevo 'jj evolog'
abbr jevolog 'jj evolog'

# Split commits (replaces hsp)
abbr jsp 'jj split'
abbr jspm --set-cursor 'jj split -m "%"'
abbr jspp --set-cursor 'jj split --parallel -m "%"'

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
abbr jned 'jj next --edit'

abbr jpr 'jj prev'
abbr jprr 'jj prev 2'
abbr jprrr 'jj prev 3'
abbr jprrrr 'jj prev 4'
abbr jprd 'jj prev --edit'

# ------------------------------------------------------------------------------
# 7. Rebase Operations
# ------------------------------------------------------------------------------
abbr jrb 'jj rebase'
# Rebase current commit + descendants TO destination
abbr jrbt --set-cursor 'jj rebase -s @ -d %'
# Rebase current commit TO p4base, main, or master (matches grm)
abbr jrbtb 'jj rebase -s @ -d p4base'
abbr jrbtm 'jj rebase -s @ -d main'
abbr jrbm 'jj rebase -d master'
abbr jrbo 'jj rebase -d master@origin'
# Rebase entire branch/chain TO destination
abbr jrbbt --set-cursor 'jj rebase -b @ -d %'
# Rebase source commit TO current commit
abbr jrbf --set-cursor 'jj rebase -s % -d @'
# Rebase source branch TO current commit
abbr jrbbf --set-cursor 'jj rebase -b % -d @'
# Rebase ONLY current revision without moving descendants
abbr jrbr --set-cursor 'jj rebase -r @ -d %'
# Insert commit before / after target
abbr jrbib --set-cursor 'jj rebase -s % --insert-before @'
abbr jrbia --set-cursor 'jj rebase -s % --insert-after @'
# Undo accidental rebase (replaces hrba)
abbr jrba 'jj undo'

# ------------------------------------------------------------------------------
# 8. Restore & Abandon (Replaces hg revert / drop)
# ------------------------------------------------------------------------------
# Restore file(s) in working copy from parent commit (replaces hr)
abbr jr --set-cursor 'jj restore %'
# Restore all modified files in working copy (replaces hra)
abbr jra 'jj restore'
# Restore files from specific revision or base
abbr jrf --set-cursor 'jj restore --from %'
abbr jrfb 'jj restore --from p4base'
abbr jrfm 'jj restore --from main'

# Discard/Abandon working copy or specific revision (replaces hdp)
abbr jabd 'jj abandon'
abbr jabr --set-cursor 'jj abandon %'

# ------------------------------------------------------------------------------
# 9. Conflict Resolution
# Note: Removing conflict markers from files auto-resolves them in jj.
# ------------------------------------------------------------------------------
abbr jrl 'jj resolve --list'
abbr jro --set-cursor 'jj resolve --tool :ours %'
abbr jrt --set-cursor 'jj resolve --tool :theirs %'
abbr jres 'jj resolve'

# ------------------------------------------------------------------------------
# 10. Code Formatting & Composite Workflows
# ------------------------------------------------------------------------------
# Format changed files
abbr jf 'jj fix'

# All-in-one fix, upload, presubmit, mail chains (replaces haa, hauc, haps, haml)
abbr jaa 'fixts; jj fix; fixbuild'
abbr jaas 'fixts; jj fix; fixbuild; jj squash -u'
abbr jauc 'fixts; jj fix; fixbuild; jj piper upload'
abbr japs 'fixts; jj fix; fixbuild; jj piper upload; jj piper presubmit --detach'
abbr jaml 'fixts; jj fix; fixbuild; jj piper upload; jj piper presubmit --detach; jj piper mail'
abbr jaucpsh 'jj piper upload; jj piper presubmit --detach && jj piper mail'

# ------------------------------------------------------------------------------
# 11. Critique & Piper Lifecycle (Upload, Presubmit, Mail, Submit, Sync, Patch)
# ------------------------------------------------------------------------------
# Upload CLs to Critique (replaces huc, hut)
abbr juc 'jj piper upload'
abbr jupc 'jj piper upload'
abbr jut 'jj piper upload -r "reachable(@, mutable())"'
abbr jupt 'jj piper upload -r "reachable(@, mutable())"'
abbr jupa 'jj piper upload --all'
abbr jupe 'jj piper upload --exported'
abbr jupr --set-cursor 'jj piper upload -r %'
abbr jupo 'jj piper upload --overwrite-remote-changes'
abbr jupp 'jj piper upload -p'

# Presubmit
abbr jps 'jj piper presubmit'
abbr jpsd 'jj piper presubmit --detach'
abbr jpse 'jj piper presubmit --eager'

# Mail (replaces hml)
abbr jml --set-cursor 'jj piper mail --reviewers %'
abbr jmla 'jj piper mail'
abbr jmll 'jj piper mail --lucky'
abbr jmlf 'jj piper mail --find-reviewers'
abbr jmlr 'jj piper mail --remail'
abbr jmlp 'jj piper mail --reviewers $PRIMARY_REVIEWER'

# Submit (replaces hsb, sub)
abbr jsb 'jj piper submit'
abbr jsbd 'jj piper submit --detach'
abbr jsba 'jj piper submit --autosync'

# Sync (replaces hsy)
abbr jsy 'jj piper sync'
abbr jsya 'jj piper sync --all'
abbr jsyn 'jj piper sync --none'
abbr jsyc --set-cursor 'jj piper sync --cl %'

# Drop CL from Critique/Piper (replaces hcld)
abbr jcld --set-cursor 'jj piper cls drop --skip-confirmation %'
abbr jcldk --set-cursor 'jj piper cls drop --skip-confirmation --keep-local %'

# Import / Patch CL from Piper (replaces hpa)
abbr jpa --position anywhere 'jj piper patch'
abbr jpad --position anywhere --set-cursor 'jj piper patch --duplicate %'
abbr jpan --position anywhere --set-cursor 'jj piper patch --no-adopt %'
abbr jpas --position anywhere --set-cursor 'jj piper patch --squash-diffbases %'

# Piper Linter Findings
abbr jli 'jj piper lint'
abbr jlir --set-cursor 'jj piper lint -r %'

# Quick personal commits + sync (replaces harcd, harcs)
abbr jcd 'jj commit -m "Update personal g3docs"; jj fix; jj piper upload; jj piper submit; jj piper sync'
abbr jcs 'jj commit -m "Update personal scripts"; jj fix; jj piper upload; jj piper submit; jj piper sync'

# ------------------------------------------------------------------------------
# 12. Bookmarks (Matches Git Branch gb / gba / gbd / gbm / gbt)
# ------------------------------------------------------------------------------
# Primary Git-matching abbreviations (gb -> jb)
abbr jb 'jj bookmark'
abbr jbl 'jj bookmark list'
abbr jba 'jj bookmark list --all'
abbr jbla 'jj bookmark list --all'
abbr jbs --set-cursor 'jj bookmark set % -r @'
abbr jbc --set-cursor 'jj bookmark create % -r @'
abbr jbm --set-cursor 'jj bookmark move % --to @'
abbr jbr --set-cursor 'jj bookmark rename %'
abbr jbd --set-cursor 'jj bookmark delete %'
abbr jbdel --set-cursor 'jj bookmark delete %'
abbr jbt --set-cursor 'jj bookmark track % --remote origin'
abbr jbu --set-cursor 'jj bookmark untrack % --remote origin'

# Extended jbk* aliases
abbr jbk 'jj bookmark'
abbr jbkl 'jj bookmark list'
abbr jbks --set-cursor 'jj bookmark set % -r @'
abbr jbkc --set-cursor 'jj bookmark create % -r @'
abbr jbkm --set-cursor 'jj bookmark move % --to @'
abbr jbkr --set-cursor 'jj bookmark rename %'
abbr jbkd --set-cursor 'jj bookmark delete %'
abbr jbkf --set-cursor 'jj bookmark forget %'
abbr jbkt --set-cursor 'jj bookmark track % --remote origin'
abbr jbku --set-cursor 'jj bookmark untrack % --remote origin'
abbr jbkda 'jj bookmark list -T "if(remote, \"\", name ++ \"\n\")" | while read -l b; test -n "$b" && jj bookmark delete "$b"; end'

# ------------------------------------------------------------------------------
# 13. File Operations (History Preserving)
# ------------------------------------------------------------------------------
abbr jmv --set-cursor 'jj piper rename %'
abbr jcp --set-cursor 'jj piper copy %'
abbr jmva --set-cursor 'jj piper rename --after %'
abbr jcpa --set-cursor 'jj piper copy --after %'
abbr jft --set-cursor 'jj file track %'
abbr jfut --set-cursor 'jj file untrack %'

# ------------------------------------------------------------------------------
# 14. CitC Workspace Navigation & Management
# ------------------------------------------------------------------------------
abbr jgoto --set-cursor 'cd (jj piper jjd %)'
abbr jmkws --set-cursor 'cd (jj piper jjd -f %)'
abbr jwsl 'jj piper citc list'
abbr jwsd --set-cursor 'jj piper citc delete %'

# ------------------------------------------------------------------------------
# 15. Git & GitHub Interoperability
# ------------------------------------------------------------------------------
# Push (Matches gp / gpd / gpp)
abbr jp 'jj git push'
abbr jgp 'jj git push'
abbr jgpa 'jj git push --all'
abbr jpb --set-cursor 'jj git push -b %'
abbr jgpb --set-cursor 'jj git push -b %'
abbr jgpc --set-cursor 'jj git push -c %'
abbr jpd 'jj git push --deleted'
abbr jgpd 'jj git push --deleted'
abbr jpn 'jj git push --dry-run'
abbr jgpn 'jj git push --dry-run'

# Fetch & Pull / Rebase (Matches gf / gl / glr / gpp)
abbr jgf 'jj git fetch'
abbr jgfa 'jj git fetch --all-remotes'
abbr jgl 'jj git fetch && jj rebase -d master@origin'
abbr jglr 'jj git fetch && jj rebase -d master@origin'
abbr jpp 'jj git fetch && jj rebase -d master@origin && jj git push'

# Remotes & Sync
abbr jgr 'jj git remote list'
abbr jgra --set-cursor 'jj git remote add %'
abbr jgi 'jj git import'
abbr jge 'jj git export'

# Commits (Matches gc / gcm)
abbr jgc 'jj commit'
abbr jgcm --set-cursor 'jj commit -m "%"'

# Init & Clone (Matches gcl)
abbr jgco 'jj git init --colocate'
abbr jgcl --set-cursor 'jj git clone %'

# Advance parent bookmark to commit to push (@-) and push to GitHub
abbr jbp "jj bookmark move --from 'heads(::@- & bookmarks())' --to @- && jj git push"
abbr jbmp "jj bookmark move --from 'heads(::@- & bookmarks())' --to @- && jj git push"
abbr jbpt "jj bookmark move --from 'heads(::@ & bookmarks())' --to @ && jj git push"
abbr jbm "jj bookmark move --from 'heads(::@- & bookmarks())' --to @-"
