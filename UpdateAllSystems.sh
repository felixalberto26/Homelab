#!/bin/bash -e
#echo "It's Starting $date" >> /root/Update.log

# list of container ids we need to iterate through
containers=$(/usr/sbin/pct list | tail -n +2 | grep 'running'  | cut -f1 -d' ')
container_count=$(($(echo "$containers" | wc -l)))

counter_file="/tmp/container_counter"
echo 0 > $counter_file

function increment_counter() {
  (
    flock -x 200
    count=$(cat $counter_file)
    count=$((count + 1))
    echo $count > $counter_file
  ) 200>"/tmp/counter_lock"
}

#echo "There are $container_count containers"
function update_container() {
  container=$1
  #echo "------------------->        [Info] Updating $container" 
  # to chain commands within one exec we will need to wrap them in bash
	#pct exec $container sudo ./UpdateSystem.sh
	/usr/sbin/pct exec $container rm UpdateSystem.sh &> /dev/null || true &> /dev/null
	#echo "Updated Container $container on 1" >> /root/Update.log
	/usr/sbin/pct push $container UpdateSystem.sh /root/UpdateSystem.sh &> /dev/null
	#echo "Updated Container $container on 2" >> /root/Update.log
	/usr/sbin/pct exec $container chmod +x UpdateSystem.sh &> /dev/null
	#echo "Updated Container $container on 3" >> /root/Update.log
	/usr/sbin/pct exec $container sudo ./UpdateSystem.sh &> /dev/null || ./UpdateSystem.sh &> /dev/null
	#echo "Updated Container $container on 4" >> /root/Update.log
	date=$(date +%Y_%m_%d)
	echo "Updated Container $container on $date" >> /root/logs/log.Update
	increment_counter
	final_count=$(cat $counter_file)
        echo "Updated Container $container : $final_count/$container_count"
}

for container in $containers
do
#status=`/usr/sbin/pct status $container`
#if [ "$status" == "status: running" ]; then
#    echo [Info] updating $container
    update_container $container &
#> /dev/null &
#fi
done; 
wait


#echo 'Updating Node'
#sh ./UpdateSystem.sh
#echo 'Node Updated'
#echo "It's Ending $date" >> /root/Update.log
