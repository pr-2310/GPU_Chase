Done by Prithvi (pc3427)

# GPU Chase in Google Cloud: A Quick Guide
- Done by Prithvi (pc3427)

Welcome to my GPU Chase script guide! This simple bash script is designed to help small companies find and use a GPU on Google Cloud Platform (GCP) for urgent AI model tasks without the need for premium support. Below, you'll find straightforward instructions on how to use this script to automate the search for available GPUs, attempt to create a VM with the GPU, and manage resources efficiently.

## Prerequisites

Before running the script, ensure you have the following:

- A GCP account and a project set up.
- Google Cloud SDK (gcloud command-line tool) installed and configured for your project.
- Basic familiarity with terminal or command-line interfaces.

## Configuration

1. **Import**: Import shell script file table_main.sh to google cloud cli workspace.
2. **Project ID**: Replace `"core-verbena-328218"` with your actual GCP project ID in the script.
3. **Image Family and Boot Disk Size**: Defaults are set to use Debian 12 with a 200GB boot disk. Adjust if necessary for your specific requirements.

## Running the Script

1. Open your terminal or command-line interface.
2. Navigate to the directory containing the script.
3. Make the script executable by running `chmod +x <script_name>.sh`.
4. Execute the script by typing `./<script_name>.sh`.

## What the Script Does

1. **Searches for GPUs**: It checks each operational zone in GCP for available NVIDIA GPUs.
2. **Attempts VM Creation**: When a GPU is found, it tries to create a VM with the specified GPU, image, and disk size.
3. **Verifies and Cleans Up**: After creating a VM, it verifies the GPU's functionality and then deletes the VM to avoid extra costs.

## Understanding the Output

- The script outputs messages to inform you of its progress, including whether GPUs are available in each zone, whether the VM creation was successful, and the outcome of the GPU verification process.
- If a VM is successfully created and verified, it will be automatically deleted afterward to prevent additional charges.

## Troubleshooting

- **Permissions**: Ensure your gcloud command-line tool is configured with an account that has necessary permissions to create and manage VM instances in your GCP project.
- **Quotas**: If VM creation fails due to quota issues, check your GCP quotas for CPUs and GPUs in the respective zone and request an increase if needed.

## Final Notes

This script is a handy tool for quickly finding available GPU resources in Google Cloud without manual search effort. Remember to monitor your GCP console for any resources created and ensure they are appropriately managed to avoid unintended expenses.

Good luck with your GPU chase!
