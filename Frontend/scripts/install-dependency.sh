#/bin/bash

codemirror_url=https://codemirror.net/codemirror.zip
codemirror_version=codemirror-5.57.0

frontend_root="$(cd "$(dirname $0)/../" && pwd)" 

third_party_dir=$frontend_root/third-party

if [ ! -e $third_party_dir/$codemirror_version ]; then
  (cd $third_party_dir && \
    curl $codemirror_url -o $codemirror_version.zip && \
    unzip $codemirror_version.zip && \
    ln -sf $codemirror_version codemirror
  )
fi

"$frontend_root/../scripts/install-toolchain.sh"