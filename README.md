This is the top-level repository for the DART project. Check out the [project webpage](http://cps-sei.github.io/dart) and [wiki](https://github.com/cps-sei/dart/wiki) for more details.

Installers for odroid/ARM using the Hardkernel repos may find the additional instructions below the Changelog helpful for installing other packages not available via 'apt-get'

#### Changelog
**2016-04-20 : [v0.3.1]** Added new scenarios to DMPLC.

**2016-04-14 : [v0.3.0]** Bug fixes to DMPLC. New built-in DMPL functions, e.g., PRINT() and EXIT(). Ported to latest V-REP version 3.3.0.

**2016-01-21 : [v0.2.3]** Added a laser range finder to the quadcopter model. Ported to latest V-REP version 3.2.3.
            
**2015-12-17 : [v0.2.2]** Updated to new MADARA and GAMS. There have been major changes in these two packages since our last release.

**2015-12-03 : [v0.2.1]** First 0.2 release. This has the DMPLC that supports the new DMPL syntax with roles and constructors.

**2015-11-26 : [v0.1]**   First public release.

####
# odroid tips
####

#
# these helper instructions were gleaned from:
#
# http://blog.boyeau.com/quick-install-install-apache-ant-on-odroid/
#

tar xfz apache-ant-1.9.6-bin.tar.gz
rm -rf apache-ant-1.9.6/manual
mkdir /opt/java
mv apache-ant-1.9.6 /opt/java
update-alternatives --install /usr/bin/ant ant /opt/java/apache-ant-1.9.6/bin/ant 1

#
# these helper instructions were gleaned from:
#
# http://blog.boyeau.com/quick-install-install-java-on-odroid-ubuntu-server-14-04/
#

tar xfz jdk-8u77-linux-arm32-vfp-hflt.tar.gz
mkdir /usr/lib/jvm
mv jdk1.8.0_77 /usr/lib/jvm/
export PATH=$PATH:/usr/lib/jvm/jdk1.8.0/bin
update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.8.0_77/bin/javac 1
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_77/bin/java 1
update-alternatives --config javac
update-alternatives --config java

