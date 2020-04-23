# multipass configuration
size=$(basename $0 | sed 's/^.*-\(.*\)\.sh/\1/')

IMAGE=18.04
case $size in
   big)
      CPU=2
      MEMORY=4G
      DISK=40G
      ;;
   small)
      CPU=1
      MEMORY=1G
      DISK=10G
      ;;
   small16)
      CPU=1
      MEMORY=1G
      DISK=10G
      IMAGE=16.04
      ;;
   controller)
      CPU=4
      MEMORY=4G
      DISK=80G
      ;;
   *)
      CPU=1
      MEMORY=1G
      DISK=10G
      ;;
esac
echo "using template: ${size} with cpu: $CPU mem $MEMORY disk $DISK"
# ssh-key file
SSHKEY=id_rsa_multipass
# hosts file. Gets read by dnsmasq
HOSTFILE=~/Code/hosts
# ansible inventory. I'm using ANSIBLE_INVENTORY.
AHOSTFILE=$ANSIBLE_INVENTORY

CLOUDINIT=~/Code/multipass/cloud-init-template.yaml


initsshkey() {
    # works.
    echo "initializing the ssh key"
    echo -e 'y\n' | ssh-keygen -q -t rsa -C "$(whoami)@nginx" -N "" -f ~/.ssh/${SSHKEY} 2>&1 > /dev/null
}

updatecloudinit() {
    # works.
    echo "preparing the cloud init file"
    name=$1
    cp $CLOUDINIT ${name}-cloudinit.yaml 
    sed -i '' "s,ssh-rsa.*$,$(cat ~/.ssh/${SSHKEY}.pub),g" ${name}-cloudinit.yaml

}
updatehostfile() {
    # works.
    echo "updating the hosts file"
    hostline=$(multipass ls | awk "/$1/{print \$3,\$1}")
    # delete previous entry
    sed -i '' "/${1}$/d" $HOSTFILE
    echo $hostline >> $HOSTFILE
    # kick dnsmasq to reread hosts
    sudo kill -s SIGHUP $(pgrep dnsmasq)
}
updateansibleinventory() {
    echo "updating ansible inventory" 
    entry="${1} ansible_port=22 ansible_host=${1} ansible_python_interpreter=/usr/bin/python3 ansible_ssh_user=nginx"
    sed -i '' "/${1}$/d" $AHOSTFILE
    echo $entry >> $AHOSTFILE
}

createsshconfig() {
    echo "creating the ~/.ssh/config/multipass/<file>"
    # works.
    # scan for hostkey and add to ~/.ssh/known_hosts
    ip=$(multipass ls | awk "/$1/{print \$3}")
    rsakey=$( ssh-keyscan -t rsa ${ip} ) 
    # delete old key
    sed -i '' "/${ip}/d" ~/.ssh/known_hosts
    echo $rsakey >> ~/.ssh/known_hosts
    # updating local ssh configuration.
    echo "Host $1\n\tHostname ${ip}\n\tUser nginx\n\tIdentityFile ~/.ssh/${SSHKEY}" > ~/.ssh/multipass/multipass-${1}.config
    #fi
}


instancelaunch() {
    echo "launching the instance"
    # works.
    if [ ! -f ~/.ssh/${SSHKEY} ]
    then 
        initsshkey
    fi
    updatecloudinit $1
    # fire up the instance
    multipass launch -c$CPU -m$MEMORY -d$DISK -n $1 $IMAGE --cloud-init $1-cloudinit.yaml
    rm $1-cloudinit.yaml
    updatehostfile $1
    # update ssh configuration
    createsshconfig $1
    # update ansible inventory
    updateansibleinventory $1
}

instancedestroy() {
    # delete the instance
    multipass delete $1
    # remove from hosts file/dnsmasq
    sed -i '' "/$1/d" $HOSTFILE
    sudo kill -s SIGHUP $(pgrep dnsmasq)
    sed -i '' "/$1/d" $AHOSTFILE
    rm ~/.ssh/multipass/multipass-${1}.config
    # should clean up known_hosts too I guess.
    multipass purge
}
case $1 in
    launch)
        instancelaunch $2
        ;;
    destroy)
        instancedestroy $2
        ;;
    rebuild)
        instancedestroy $2
        instancelaunch $2
        ;;
    nuclear)
        multipass ls | grep -v State | cut -d" " -f1 | while read vm ; do instancedestroy $vm ; done
        ;;
    status)
        if [ ! -z $2 ]
        then
            multipass ls | egrep "^Name|${2}"
        else
            multipass ls
        fi
        ;;
*)
        echo "Unsupported argument(s)"
        exit 1
        ;;
esac
