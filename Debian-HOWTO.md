# Debian Installation and Use Howto

This how-to MAY be applicable to other linux distros.  This was written while making stuff work
on a Debian Jessie virtual machine that was upgraded from Debian Wheezy.

# Prep

First off, remove the included hdf5 distro.  You need 1.8.15, Jessie stable comes
with 1.8.13.

```
sudo apt-get remove libhdf5-dev
```

Download the source for hdf5 ans szip from hdf5's webpage and un-tar it, compile, test, and install it:
```
wget http://www.hdfgroup.org/ftp/lib-external/szip/2.1/src/szip-2.1.tar.gz
gunzip szip-2.1.tar.gz
tar -xf szip-2.1.tar
rm szip-2.1.tar
cd szip-2.1
./configure --prefix=/usr/local/hdf5
make
sudo make install

wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.15-patch1.tar
tar -xf hdf5-1.8.15-patch1.tar
rm hdf5-1.8.15-patch1.tar
cd hdf5-1.8.15-patch1
./configure --prefix=/usr/local/hdf5 --enable-cxx --with-szlib=/usr/local/hdf5/lib
make
make check
sudo make install
sudo make check-install
```

At this time, there should be necessary .so files in /usr/local/hdf5/lib.  You need these in the linker
path.  To add them:
```
cd /etc/ld.so.conf.d
sudo touch hdf5.conf
```
Add (only) the line /usr/local/hdf5/lib to hdf5.conf (use whatever editor you like).  
Then, reload the linker:
```
sudo ldconfig
```

# Landing

Install Ruby and Rails:
```
sudo apt-get install ruby
sudo apt-get install rubygems
gem install rails
