#su
apt-get install unzip curl

#exit su
curl http://dub.sh/kifont.zip -LO
mkdir /home/kiosk/.fonts
unzip kifont.zip -d /home/kiosk/.fonts
fc-cache -f -v
