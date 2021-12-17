for remote_name in $(git remote); do 
    git remote remove "${remote_name}"
done

HILDESHEIM="https://software.ismll.uni-hildesheim.de/rscholz/python-venv.git"
BERLIN="https://git.tu-berlin.de/bvt-htbd/kiwi/tf1/python-venv.git"

git remote add berlin $BERLIN
git remote set-url --add --push berlin $BERLIN
git remote set-url --add --push berlin $HILDESHEIM

git remote add hildesheim $HILDESHEIM
git remote set-url --add --push hildesheim $BERLIN
git remote set-url --add --push hildesheim $HILDESHEIM

git remote -v

git fetch berlin
git branch --set-upstream-to=berlin/main  main
git push -u berlin --all

