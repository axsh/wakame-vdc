here="$( cd "$( dirname "$0" )" && pwd )"
BUILD=$1
APTCONF=${here}/release.conf
DISTNAME=lucid

cd $BUILD
apt-ftparchive -c $APTCONF generate ${here}/apt-ftparchive-deb.conf
apt-ftparchive -c $APTCONF generate ${here}/apt-ftparchive-udeb.conf
apt-ftparchive -c $APTCONF generate ${here}/apt-ftparchive-extras.conf
apt-ftparchive -c $APTCONF release $BUILD/dists/$DISTNAME > $BUILD/dists/$DISTNAME/Release

[[ -z "${FLAG_WITHOUT_GPG_SIGN}" ]] || {
  gpg --default-key "DCFFB6BE" --output $BUILD/dists/$DISTNAME/Release.gpg -ba $BUILD/dists/$DISTNAME/Release
}
find . -type f -exec md5sum {} \; > md5sum.txt
