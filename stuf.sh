
# new branch, add to .git/config as per example/other branches
# then:
# for each branch:
#git co -b 963 origin/963

# to get updated:

git co master
git pull
for i in $(git br -r | grep -Eo "[0-9]{3,}" | tr "\n" " ")
do 
    git co $i
    git svn fetch
    git svn rebase
done
