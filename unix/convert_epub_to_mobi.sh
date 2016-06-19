sudo apt-get install calibre

for i in $(find $(pwd) -name '*.epub' -printf '%P\n'); do ebook-convert $i ${i/epub/mobi}; 