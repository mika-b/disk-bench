#!/bin/sh

TARGET="$1"

fio2cdm() {
    awk '
    /^Seq-Read:/          {getline;if($1~/^read/) {seqread =$4}}
    /^Seq-Write:/         {getline;if($1~/^write/){seqwrite=$3}}
    /^Rand-Read-512K:/    {getline;if($1~/^read/) {rread512 =$4}}
    /^Rand-Write-512K:/   {getline;if($1~/^write/){rwrite512=$3}}
    /^Rand-Read-4K:/      {getline;if($1~/^read/) {rread4 =$4}}
    /^Rand-Write-4K:/     {getline;if($1~/^write/){rwrite4=$3}}
    /^Rand-Read-4K-QD32:/ {getline;if($1~/^read/) {rread4qd32 =$4}}
    /^Rand-Write-4K-QD32:/{getline;if($1~/^write/){rwrite4qd32=$3}}
    function n(i) {
    	split(gensub(/bw=([0-9.]+)(([KM]?)B\/s,)?/,"\\1 \\3", "g", i), a);
	s = a[1]; u = a[2];
	if(u == "K") {s /= 1024}
	if(u == "")  {s /= 1024 * 1024}
	return s;
    }
    END {
    	print ("|      | Read(MB/s)|Write(MB/s)|");
	print ("|------|-----------|-----------|");
        printf("|  Seq |%11.3f|%11.3f|\n", n(seqread),   n(seqwrite));
        printf("| 512K |%11.3f|%11.3f|\n", n(rread512),  n(rwrite512));
        printf("|   4K |%11.3f|%11.3f|\n", n(rread4),    n(rwrite4));
        printf("|4KQD32|%11.3f|%11.3f|\n", n(rread4qd32),n(rwrite4qd32));
    }
    '
}

trap "rm -f ${TARGET}/.fio-diskmark" 0 1 2 3 9 15

# see. http://www.winkey.jp/article.php/20110310142828679
cat <<_EOL_ | fio - | fio2cdm
[global]
ioengine=libaio
iodepth=1
size=1g
direct=1
runtime=60
directory=${TARGET}
filename=.fio-diskmark

[Seq-Read]
bs=1m
rw=read
stonewall

[Seq-Write]
bs=1m
rw=write
stonewall

[Rand-Read-512K]
bs=512k
rw=randread
stonewall

[Rand-Write-512K]
bs=512k
rw=randwrite
stonewall

[Rand-Read-4K]
bs=4k
rw=randread
stonewall

[Rand-Write-4K]
bs=4k
rw=randwrite
stonewall

[Rand-Read-4K-QD32]
iodepth=32
bs=4k
rw=randread
stonewall

[Rand-Write-4K-QD32]
iodepth=32
bs=4k
rw=randwrite
stonewall
_EOL_

