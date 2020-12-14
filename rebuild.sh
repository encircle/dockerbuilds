#!/bin/bash

# determine versions
latest_version=$(grep -o v[0-9].[0-9].[0-9] CHANGELOG.txt | tail -1)
next_version=$(echo $latest_version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
echo "Current version is ${latest_version}, incrementing to ${next_version}"

# update changelog
sed -i -E "s/${latest_version}.+/${latest_version}/g" CHANGELOG.txt
echo -e "\n${next_version} (latest)"     >> CHANGELOG.txt
echo "======"                          >> CHANGELOG.txt
echo "- Rebuild only, no code changes" >> CHANGELOG.txt

# update git
git commit -a -m 'rebuild only, no code changes'
git tag ${next_version}
git push --tags
git push origin master
