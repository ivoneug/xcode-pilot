# Source instead of `export $(xargs < project.env)`: the latter word-splits on the unquoted
# command substitution, so any value containing a space is silently truncated at the space.
set -a
. ./project.env
set +a
xcodegen --spec xcodegen/project.yml --project ../
