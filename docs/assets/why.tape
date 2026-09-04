# VHS tape for the README demo GIF (https://github.com/charmbracelet/vhs).
# Run from a native-federation/devtools checkout with casefile on PATH:
#
#   cd <devtools-checkout> && vhs <casefile-repo>/docs/assets/why.tape
#
# The rendered why.gif lands in the current directory; move it to
# docs/assets/why.gif in the casefile repo. Real commands, real repo —
# nothing staged.

Output why.gif
Set Shell "bash"
Set FontSize 20
Set Width 1420
Set Height 520
Set Padding 20
Set TypingSpeed 40ms

Type "git blame -s -L 7,7 projects/devtools-ui/src/app/app.html"
Enter
Sleep 3s

Type "# a sha. but *why* is the Diagnostics tab hidden?"
Enter
Sleep 2s

Type "casefile why projects/devtools-ui/src/app/app.html:7 --head 8"
Enter
Sleep 8s
