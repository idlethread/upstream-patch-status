#!/bin/sh

# Script to query patchwork to see if a list of patches on applied to a tree
# were posted upstream or not
#  - By Amit Kucheria

# Assumption:
#  Run in the kernel source git tree on the release branch
#  pwclient (from patchwork sources) is installed and available in PATH

# Script is meant to be run on RPK.
# Input:
#  <rpk release version>
#  <vanilla kernel version>
#
# Output:
#  file containing SHA, Author and Subject of patches

RPB_VERSION=${1:?"Usage: $0 <rpb version> <vanilla kernel version>"}
VANILLA_KERNEL=${2:?"Usage: $0 <rpb version> <vanilla kernel version>"}
PATCH_FNAME=~/tmp/rpk-${RPB_VERSION}.patchlist
PATCH_NOUP_FNAME=~/tmp/rpk-${RPB_VERSION}-noup.patchlist
PATCH_HACK_FNAME=~/tmp/rpk-${RPB_VERSION}-hack.patchlist
PATCH_REVISIT_FNAME=~/tmp/rpk-${RPB_VERSION}-revisit.patchlist
PATCH_REVERT_FNAME=~/tmp/rpk-${RPB_VERSION}-revert.patchlist
PATCH_MISC_FNAME=~/tmp/rpk-${RPB_VERSION}-misc.patchlist

TMP=$(mktemp -p /tmp)
TMP1=$(mktemp -p /tmp)

# Dump list of all patches except merges to a file and remove the bits that
# shouldn't be checked for upstream e.g. {noup}, {temphack}, Revert
#  '@' chosen as delimiter to allow easier filtering of subject lines
git log --pretty=format:"%s@ %h@ %an" --no-merges v${VANILLA_KERNEL}..  > $TMP
#git log --pretty=format:"%s" --no-merges v${VANILLA_KERNEL}..  > $TMP

echo "Total patches in $RPB_VERSION on $VANILLA_KERNEL: `wc -l $TMP`"

grep -i "noup" $TMP > $PATCH_NOUP_FNAME
grep -i "temphack" $TMP > $PATCH_HACK_FNAME
grep -i "revisit" $TMP > $PATCH_REVISIT_FNAME
grep -i "Revert" $TMP > $PATCH_REVERT_FNAME
grep -E "topost|fromlist|fromtree" $TMP > $PATCH_MISC_FNAME

grep -v -E "noup|temphack|REVISIT|Revert" $TMP > $TMP1

echo "Functional patches after filtering: `wc -l $TMP1`"

grep -v -E "topost|fromlist|fromtree" $TMP1 > $PATCH_FNAME

# Start processing....

# XXXX: Process PATCH_MISC_FNAME here
cat $PATCH_MISC_FNAME | cut -d'@' -f1 | cut -d'}' -f2 | while read subj
do
	printf "$subj @"
done

#cat $PATCH_FNAME | cut -d'@' -f1 | head -n5 | while read subj
cat $PATCH_FNAME | cut -d'@' -f1 | while read subj
do
	printf "$subj @"
	ret=`pwclient list -p LKML -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " LKML"
		continue
	fi
	ret=`pwclient list -p linux-arm-kernel -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " linux-arm-kernel"
		continue
	fi
	ret=`pwclient list -p linux-pci -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " linux-pci"
		continue
	fi
	ret=`pwclient list -p linux-acpi -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " linux-acpi"
		continue
	fi
	ret=`pwclient list -p kvm -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " kvm"
		continue
	fi
	ret=`pwclient list -p dri-devel -f %{name} "$subj" | wc -l`
	if [ $ret -gt "0" ]; then
		echo " dri-devel"
		continue
	fi
	echo " Not posted to known lists"
#	echo "pwclient list -p LKML -f %{name} \"$subj\""
done
