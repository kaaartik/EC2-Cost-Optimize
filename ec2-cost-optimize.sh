#!/bin/bash
# Author: Kartik
# Description: Stop running EC2 instances and manage their EBS volumes by creating snapshots, detaching, and optionally deleting them.
# Version: V2

REGION="us-east-1"  # Replace with your AWS region

echo "Starting EC2 and EBS cost optimization script..."

# Stop all running instances
echo "Fetching all running instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

echo "Found running instance IDs: '$INSTANCE_IDS'"

if [ -z "$INSTANCE_IDS" ]; then
    echo "No running instances found to stop."
else
    INSTANCE_IDS=$(echo "$INSTANCE_IDS" | xargs)
    echo "Stopping instances: $INSTANCE_IDS"
    STOP_OUTPUT=$(aws ec2 stop-instances --instance-ids $INSTANCE_IDS --region $REGION 2>&1)
    if [ $? -ne 0 ]; then
        echo "Failed to stop instances: $INSTANCE_IDS"
        echo "Error: $STOP_OUTPUT"
        exit 1
    else
        echo "Instances stopped successfully: $INSTANCE_IDS"
    fi
fi


echo "Fetching volumes attached to stopped instances..."
STOPPED_INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=instance-state-name,Values=stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

for INSTANCE in $STOPPED_INSTANCES; do
    echo "Processing stopped instance: $INSTANCE"
    VOLUME_IDS=$(aws ec2 describe-volumes \
        --region "$REGION" \
        --filters "Name=attachment.instance-id,Values=$INSTANCE" \
        --query "Volumes[].VolumeId" \
        --output text)
    
    if [ -n "$VOLUME_IDS" ]; then
        for VOLUME_ID in $VOLUME_IDS; do
            VOLUME_ID=$(echo "$VOLUME_ID" | xargs)  # Trim whitespace
            echo "Creating snapshot for volume: '$VOLUME_ID'"

            SNAPSHOT_OUTPUT=$(aws ec2 create-snapshot \
                --region "$REGION" \
                --volume-id "$VOLUME_ID" \
                --description "Snapshot of $VOLUME_ID from $INSTANCE" 2>&1)
            
            if [ $? -eq 0 ]; then
                SNAPSHOT_ID=$(echo "$SNAPSHOT_OUTPUT" | jq -r '.SnapshotId')
                echo "Snapshot created successfully: $SNAPSHOT_ID for volume $VOLUME_ID."
                
                echo "Detaching volume $VOLUME_ID..."
                DETACH_OUTPUT=$(aws ec2 detach-volume --region "$REGION" --volume-id "$VOLUME_ID" 2>&1)
                if [ $? -eq 0 ]; then
                    echo "Volume $VOLUME_ID detached successfully."
                else
                    echo "Failed to detach volume $VOLUME_ID. Error: $DETACH_OUTPUT"
                fi
            else
                echo "Failed to create snapshot for volume $VOLUME_ID. Error: $SNAPSHOT_OUTPUT"
            fi
        done
    else
        echo "No volumes found for stopped instance $INSTANCE."
    fi
done


echo "Fetching unattached volumes..."
UNATTACHED_VOLUMES=$(aws ec2 describe-volumes \
    --region "$REGION" \
    --filters "Name=status,Values=available" \
    --query "Volumes[].VolumeId" \
    --output text)

if [ -n "$UNATTACHED_VOLUMES" ]; then
    for VOLUME_ID in $UNATTACHED_VOLUMES; do
        VOLUME_ID=$(echo "$VOLUME_ID" | xargs)  # Trim whitespace
        echo "Deleting unattached volume: '$VOLUME_ID'"
        DELETE_OUTPUT=$(aws ec2 delete-volume --region "$REGION" --volume-id "$VOLUME_ID" 2>&1)
        if [ $? -eq 0 ]; then
            echo "Volume $VOLUME_ID deleted successfully."
        else
            echo "Failed to delete volume $VOLUME_ID. Error: $DELETE_OUTPUT"
        fi
    done
else
    echo "No unattached volumes found."
fi

echo "EC2 and EBS cost optimization script completed."
