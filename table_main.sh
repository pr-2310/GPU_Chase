#!/bin/bash

# Variables
project_id="core-verbena-328218" # Replace with your actual GCP project ID
image_family="debian-12" # Use Debian 12 as the base image
boot_disk_size="200GB" # Use a 200GB boot disk
output_file="gpu_availability.txt" # Output file to store results

# Initialize output file with a header
echo "Zone | GPU Type | VM Name | Status | Comments" > "$output_file"

# Function to get the first available GPU in a zone
get_first_available_gpu() {
  local zone=$1
  gcloud compute accelerator-types list --format="value(name)" --filter="zone:($zone) AND name:nvidia*" | head -n 1
}

# Function to store output in a tabular format
store_output() {
  local zone=$1
  local gpu_type=$2
  local vm_name=$3
  local status=$4
  local comments=$5
  
  echo "$zone | $gpu_type | $vm_name | $status | $comments" >> "$output_file"
}

# Main loop to check each zone for GPU availability and attempt VM creation, limited to 10 iterations
zone_count=0
for zone in $(gcloud compute zones list --format="value(name)" --filter="status:UP" | head -n 10); do
  zone_count=$((zone_count+1))
  echo "Checking for available GPUs in $zone..."
  
  gpu_type=$(get_first_available_gpu "$zone")
  
  if [ -n "$gpu_type" ]; then
    echo "Found available GPU: $gpu_type in $zone"
    vm_name="gpu-vm-$zone"
    
    # Choose the machine type based on the GPU type
    machine_type="n1-standard-4"
    if [[ "$gpu_type" == "nvidia-l4" ]]; then
      machine_type="g2-standard-4"
    elif [[ "$gpu_type" == *"a100-40gb"* ]]; then
      machine_type="a2-highgpu-1g"
    elif [[ "$gpu_type" == *"a100-80gb"* ]]; then
      machine_type="a2-ultragpu-1g"
    elif [[ "$gpu_type" == *"h100-80gb"* ]]; then
      machine_type="a3-highgpu-8g"
    fi
    
    # Attempt to create a VM with the available GPU type
    echo "Attempting to create VM ($vm_name) in zone $zone with GPU type $gpu_type and machine type $machine_type"
    if gcloud compute instances create "$vm_name" \
      --zone="$zone" \
      --project="$project_id" \
      --machine-type="$machine_type" \
      --accelerator="type=$gpu_type,count=1" \
      --image-family="$image_family" \
      --image-project="debian-cloud" \
      --boot-disk-size="$boot_disk_size" \
      --maintenance-policy=TERMINATE \
      --metadata=startup-script='#! /bin/bash
      echo "Checking NVIDIA GPU availability..."
      nvidia-smi
      lspci | grep -i nvidia
      echo "Installing CUDA Toolkit..."
      sudo apt-get update
      sudo apt-get install -y wget software-properties-common
      wget https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda-repo-debian11-12-2-local_12.2.1-535.86.10-1_amd64.deb
      sudo dpkg -i cuda-repo-debian11-12-2-local_12.2.1-535.86.10-1_amd64.deb
      sudo cp /var/cuda-repo-debian11-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/
      sudo add-apt-repository contrib
      sudo apt-get update
      sudo apt-get -y install cuda
      ' \
      --quiet; then
      
      echo "VM ($vm_name) creation successful in zone $zone with GPU $gpu_type"
      store_output "$zone" "$gpu_type" "$vm_name" "Success" "VM creation successful"
      
      # Wait for the VM to initialize
      echo "Waiting for VM ($vm_name) to initialize..."
      sleep 30  # Wait 30 seconds before checking
      
      # Check VM status and retry SSH command until VM is ready or timeout is reached
      echo "Verifying GPU installation on VM ($vm_name)..."
      RETRIES=5
      COUNT=0
      while true; do
        VM_STATUS=$(gcloud compute instances describe "$vm_name" --zone="$zone" --format='get(status)')
        if [[ "$VM_STATUS" == "RUNNING" ]]; then
          if gcloud compute ssh "$vm_name" --zone="$zone" --command="lspci | grep -i nvidia"; then
            echo "GPU verified successfully on VM ($vm_name)"
            break
          fi
        fi
        if (( COUNT >= RETRIES )); then
          echo "Failed to SSH into VM ($vm_name) after $RETRIES attempts."
          break
        fi
        echo "Retrying SSH connection to VM ($vm_name) ($COUNT/$RETRIES)..."
        ((COUNT++))
        sleep 10
      done
      
      # Cleanup: Delete VM after verification
      echo "Cleaning up: Deleting VM ($vm_name) to avoid unnecessary costs."
      gcloud compute instances delete "$vm_name" --zone="$zone" --quiet
      
    else
      echo "Failed to create VM ($vm_name) in zone $zone with GPU $gpu_type"
      store_output "$zone" "$gpu_type" "$vm_name" "Failed" "VM creation failed"
    fi
  else
    echo "No available GPUs found in $zone"
    store_output "$zone" "N/A" "N/A" "Failed" "No GPU available"
  fi
  
  # Stop after checking 10 zones
  if [ "$zone_count" -eq 10 ]; then
    break
  fi
done


