#!/bin/bash
#NFSburn.sh
#Anders Nelson
#2014-6-6

#The purpose of this script will be to spin up n threads, each thread will create a randomly named file of a size between 1-10MB, rsync said file to a specified nfs mount, and then destroy the file locally. I am trying to simulate an application that writes many small files simultanously.

#THINGS TO KEEP IN MIND
#This script is sketch at best, it has not been tested thoroughly, was written by a bash scripting amature, and only focuses on getting the job done. It needs a lot more error checking if it is to be used in the long run. Watch your local disk to make sure all the parallel dds don't eat it all.

#Some Variables
MOUNT=/san/nfs-stage/nfsburn/ #your nfs mountpoint that is being tested

#First a funciton to do our work.
filetest() {
  COUNT=$(echo $RANDOM % 10 + 1 | bc) #We are going to want a file between 1 a    nd 10M in size.
  UUID=$(/usr/bin/uuidgen) #This will be our uniq file name
  test1=$(/usr/bin/test -f $UUID && echo "0" || echo "1")
  if [ $test1 == "1" ] ;
  then
    $(/bin/dd if=/dev/urandom of=$UUID bs=1M count=$COUNT) && $(/usr/bin/rsync -Pa $UUID $MOUNT) && $(/bin/rm -f $UUID)
  fi
  test2=$(/usr/bin/test -f $UUID && echo "0" || echo "1")
  if [ $test2 == "0" ] ;
  then
    echo "$UUID not deleted!"
    exit 1
  fi
}
export -f filetest


# Now we just need to run our function, a lot, and all at once! I am going to use parallel from the rpm moreutils. This is not in standard RHEL build so lets check for it.

command -v parallel >/dev/null 2>&1 || { echo >&2 "I require gnu-parallel but it's not installed.  Aborting."; exit 1; }

#Now lets hammer NFS and see what happens! Yeah thats right, I wrote 1000 threads please, I may need to tweak that.

/usr/bin/parallel filetest ::: {1..1000}

exit 0
