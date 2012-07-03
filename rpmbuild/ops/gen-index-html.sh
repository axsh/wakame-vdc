#!/bin/bash

set -e
#set -x

archs="x86_64 i686"
basearchs="x86_64 i386"
rpm_dir=pool/vdc/current
s3_repo_uri=s3://dlc.wakame.axsh.jp/packages/rhel/6/

release_id=$(
  for basearch in ${basearchs}; do
    for i in pool/vdc/current/${basearch}/wakame*.rpm; do
      file=$(basename $i)
      prefix=${file%%.el6.*.rpm}
      echo ${prefix##*-}
    done
  done | sort -r | uniq | head -1
)


cat <<EOS
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
 "http://www.w3.org/TR/html4/strict.dtd">
<html>
 <head>
  <title>Wakame-VDC Daily Build</title>
 </head>
 <body><div id="pageWrapper">

<div id="header"><a href="http://wakame.jp/"></a></div>

<h1>Wakame-VDC Daily Build</h1>

<h2>ID: ${release_id}</h2>

<div id="main">
<dl>
EOS

cd ${rpm_dir}

for basearch in ${basearchs}; do
  printf "<dt>%s</dt>\n" ${basearch}
  printf "<dd><pre>\n"
  find ${basearch}/ -type f -name "*${release_id}*" | sort | while read rpm; do
    filename=$(basename ${rpm})
    printf "<a href=\"%s\">%s</a>\n" ${rpm} ${filename}
  done
  printf "</pre></dd>\n"
done

cat <<EOS
</dl>
<hr>
</div></div></body></html>
EOS
