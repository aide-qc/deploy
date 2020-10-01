# Run the following to install
```bash 
$ wget -qO- https://aide-qc.github.io/deploy/xacc/debian/focal/PUBLIC-KEY.gpg | apt-key add -
$ echo "deb https://aide-qc.github.io/deploy/xacc/debian/focal ./" > /etc/apt/sources.list.d/xacc-focal.list
$ apt-get update
$ apt-get install xacc
```
