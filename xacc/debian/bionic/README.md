# Run the following to install
```bash 
$ wget -qO- https://aide-qc.github.io/deploy/xacc/debian/bionic/PUBLIC-KEY.gpg | apt-key add -
$ echo "deb https://aide-qc.github.io/deploy/xacc/debian/bionic ./" > /etc/apt/sources.list.d/xacc-bionic.list
$ apt-get update
$ apt-get install xacc
```
