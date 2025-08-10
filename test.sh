#su
apt-get install unzip curl

#exit su
curl http://dub.sh/kifont.zip -LO
unzip kifont.zip -d /home/kiosk/.fonts
fc-cache -f -v
