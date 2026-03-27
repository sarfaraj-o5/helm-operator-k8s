go get -d github.com/operator-framework/operator-sdk
cd $GOPATH/src/github.com/operator-framework/operator-sdk
git checkout master
make dep
make install

## Now we will have the operator-sdk binary in the $GOPATH/bin folder.      