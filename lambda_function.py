import json
import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    try:
        # Create an EC2 client
        client = boto3.client("ec2", region_name="us-east-1")

        # Describe volumes
        response = client.describe_volumes()
        
        # Check if any volumes exist
        if len(response['Volumes']) > 0:
            for volume in response['Volumes']:
                volume_id = volume['VolumeId']
                instance_id = volume['Attachments'][0].get('InstanceId', 'N/A')
                print(f'EBS volume ID: {volume_id} attached to EC2 instance: {instance_id}')
                
                try:
                    # Create snapshot
                    snapshot_description = f"Snapshot of volume {volume_id} attached to instance {instance_id}"
                    response_snapshot = client.create_snapshot(VolumeId=volume_id, Description=snapshot_description)
                    print(f'Snapshot created with id: {response_snapshot["SnapshotId"]}')
                
                except ClientError as e:
                    print(f'Error creating snapshot for volume {volume_id}: {e}')

        return {
            'statusCode': 200,
            'body': json.dumps('Success')
        }
    
    except ClientError as e:
        print(f"ClientError: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error during EC2 client operation')
        }
    
    except Exception as e:
        print(f"General error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Unexpected error')
        }
