INSTANCE_ID=$(curl -s "http://169.254.169.254/latest/meta-data/instance-id")

AWSVOLUMES=$( aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$INSTANCE_ID" )

for i in `seq 0 26`; do
    BLOCK_DEVICE="/dev/nvme$${i}n1"

    if [ -e $BLOCK_DEVICE ]; then

        VOLUME_ID=$( nvme id-ctrl $BLOCK_DEVICE | grep sn | awk '{ print $3 }' | sed -r -e 's/^.{3}/&-/' )

        MAPPING_DEVICE=$( echo $AWSVOLUMES | jq -r --arg V "$VOLUME_ID" '.[][] | .Attachments[] | select(.VolumeId == $V) | .Device' )

        if [[ "$MAPPING_DEVICE" != /dev/* ]]; then
            MAPPING_DEVICE="/dev/$MAPPING_DEVICE"
        fi

        if [ -e $MAPPING_DEVICE ]; then
            echo "path exists: $MAPPING_DEVICE"

        else
            echo "symlink created: $BLOCK_DEVICE to $MAPPING_DEVICE"
            ln -s $BLOCK_DEVICE $MAPPING_DEVICE
        fi

    fi
done


#  partition unformatted volumes

VOLUMES=$( echo $AWSVOLUMES | jq -r '.[][] | .Attachments[] | .Device' | sort )
VOLARRAY=( $VOLUMES )

for V in "$${VOLARRAY[@]}"; do 
        DEVICE=$( readlink -f $V )
        if [ "$( file -b -s $DEVICE )" == "data" ]; then
                 echo -e "o\nn\np\n1\n\n\nw" | fdisk "$DEVICE"
        fi
done

        let "DATA_COUNT = $( ls /dev/oracleasm/disks/DATA* | wc -l ) + 1"
        let "FRA_COUNT = $( ls /dev/oracleasm/disks/FRA* | wc -l ) + 1"

        for I in "$${!VOLARRAY[@]}"; do 
                VOLTAG=$( echo $AWSVOLUMES | jq -r --arg V "$${VOLARRAY[$I]}" '.Volumes[] | select(.Attachments[].Device == $V) | .Tags[] | select(.Key == "Name") | .Value' )
        
                L=$( readlink -f $${VOLARRAY[$I]} )
                P=$( lsblk -nl $L -o NAME,TYPE | grep part | cut -d ' ' -f1 )
                PARTITION="/dev/$P"

                if [[ "$VOLTAG" == *"-DATA-"* ]]; then
                        oracleasm createdisk "DATA$DATA_COUNT" "$PARTITION" 
                        ((DATA_COUNT++))
                elif [[ "$VOLTAG" == *"-FRA-"* ]]; then
                        oracleasm createdisk "FRA$FRA_COUNT" "$PARTITION" 
                        ((FRA_COUNT++))
                else
                        echo "$PARTITON is not used in DATA or FRA"
                fi
        done

        oracleasm scandisks