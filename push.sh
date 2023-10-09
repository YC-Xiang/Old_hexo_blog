git fetch
git pull

if [ $# != 1 ]; then
echo "USAGE: $0 [commit message]"
exit 1;
fi

git add .
git commit -m "$1"
git push

hexo clean
hexo g
hexo d
