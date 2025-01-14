# AWS-EC2 Cost Optimization Script

---

## 🌟 **Project Highlights**

- **Automated EC2 Cost Optimization**:
  - Stops all running EC2 instances.
  - Creates snapshots of attached EBS volumes for data backup.
  - Detaches and optionally deletes unattached volumes.
  
- **Cost Savings**:
  - Ensures zero billing for unused EC2 resources during non-peak hours.
  - Achieves up to **33% cost reduction**.

- **Cron Job Automation**:
  - Scheduled execution of the script during predefined off-hours.

---

## 📋 **Tech Stack**

- **Shell Scripting**: Bash for automating AWS EC2 and EBS operations.
- **AWS CLI**: Interacts with AWS services for managing instances and volumes.

---

## 🛠 **Setup Instructions**

### **1. Prerequisites**
- **AWS CLI**:
  - Install AWS CLI: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - Configure AWS CLI with appropriate credentials and region:
    ```bash
    aws configure
    ```
- **IAM Permissions**:
  - The IAM role or user executing the script must have the following permissions:
    - `ec2:StopInstances`
    - `ec2:DescribeInstances`
    - `ec2:CreateSnapshot`
    - `ec2:DetachVolume`
    - `ec2:DeleteVolume`

---

### **2. Clone the Repository**
```bash
git clone https://github.com/your-repo/aws-ec2-cost-optimize.git
cd aws-ec2-cost-optimize
```

---

### **3. Set Up the Script**
- Update the `REGION` variable in the script to match your AWS region.

---

### **4. Run the Script Manually**
- Make the script executable:
  ```bash
  chmod 777 ec2-cost-optimize.sh
  ```
- Execute the script:
  ```bash
  ./ec2-cost-optimize.sh
  ```

---

### **5. Automate with Cron Job**
- Schedule the script to run during off-hours using `crontab`:
  ```bash
  crontab -e
  ```
- Add the following line to schedule the script (e.g., every day at 10 PM):
  ```bash
  0 22 * * * /path/to/ec2-cost-optimize.sh >> /path/to/logs/cost-optimize.log 2>&1
  ```
