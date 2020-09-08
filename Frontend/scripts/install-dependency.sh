#/bin/bash

codemirror_url=https://codemirror.net/codemirror.zip
codemirror_version=codemirror-5.57.0

frontend_root="$(cd "$(dirname $0)/../" && pwd)" 

third_party_dir=$frontend_root/third-party

"$frontend_root/../scripts/install-toolchain.sh"
