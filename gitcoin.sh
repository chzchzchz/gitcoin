#!/bin/bash

# Welcome to gitcoin.


title="$1"
if [ -z "$title" ]; then
	title="gitcoin: "`whoami`
fi

WALLET="$HOME/.gitcoin"
mkdir -p $WALLET
if [ ! -e "$WALLET"/id_rsa.pub ]; then
	ssh-keygen <<<"$WALLET/id_rsa"
fi

x=`git log 2>&1 | head -n1 | grep fatal | cut -f1 -d':'`
if [ ! -z "$x" ]; then
	rm -f gitchain.dat
	git init
	git add *
	git commit -m "Welcome to gitcoin"
	git checkout --orphan gitbux
	git rm -f *
	touch gitchain.dat
	git add gitchain.dat
	git commit -m "Mint the first gitcoin"
fi

git checkout gitbux >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo no gitbux branch huh
	exit 1
fi

commits=`git rev-list HEAD --count`
n=`bc -l <<< "1+(l($commits)/l(2))/4" |  cut -f1 -d'.'`
x="0"
oldhash=`git log | head -n1 | grep commit | cut -f2 -d' '`
git branch -D gitbux-work
while [ 1 ]; do
	git checkout -b gitbux-work >/dev/null 2>&1
	cat $WALLET/id_rsa.pub >>gitchain.dat
	x=`expr $x + 1`
	echo "$x" >>gitchain.dat
	git add gitchain.dat >/dev/null  2>&1
	git commit -m "$title" >/dev/null 2>&1
	newhash=`git log | head -n1 | grep commit | cut -f2 -d' '`
	t=`echo $oldhash $newhash | awk '{ print substr($1,0,'$n') " == " substr($2,0,'$n'); }'`
	if [ $t ]; then
		echo "Congratulations you have mined GITCOIN!"
		echo "Old hash: $oldhash"
		echo "New hash: $newhash"
		echo $t
		echo $x
		git checkout gitbux
		git merge gitbux-work
		git checkout master
		exit
	fi
	git checkout gitbux >/dev/null 2>&1
	git branch -D gitbux-work >/dev/null 2>&1
done

