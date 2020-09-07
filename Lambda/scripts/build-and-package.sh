set -eu

executable=$1
workspace="$(cd "$(dirname $0)/../" && pwd)"
builder_dir="$workspace/builder"

echo "-------------------------------------------------------------------------"
echo "preparing docker build image"
echo "-------------------------------------------------------------------------"
docker build "$builder_dir" -t tokamak-pad-package-builder
echo "done"

echo "-------------------------------------------------------------------------"
echo "building \"$executable\" lambda"
echo "-------------------------------------------------------------------------"
docker run --rm -v "$workspace":/workspace -w /workspace tokamak-pad-package-builder \
       bash -cl "swift build --product $executable -c release"
echo "done"

echo "-------------------------------------------------------------------------"
echo "packaging \"$executable\" lambda"
echo "-------------------------------------------------------------------------"
docker run --rm -v "$workspace":/workspace -w /workspace tokamak-pad-package-builder \
       bash -cl "./scripts/package.sh $executable"
echo "done"
