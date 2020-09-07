set -eu

executable=$1
workspace="$(cd "$(dirname $0)/../" && pwd)"

echo "\ndeploying $executable"

$workspace/scripts/build-and-package.sh $executable

echo "-------------------------------------------------------------------------"
echo "uploading \"$executable\" lambda to AWS S3"
echo "-------------------------------------------------------------------------"

aws s3 cp $workspace/.build/lambda/$executable/lambda.zip s3://compile-swiftwasm/

echo "-------------------------------------------------------------------------"
echo "updating AWS Lambda to use \"$executable\""
echo "-------------------------------------------------------------------------"

aws lambda update-function-code --function "CompileSwiftWasm" --s3-bucket "compile-swiftwasm" --s3-key lambda.zip
