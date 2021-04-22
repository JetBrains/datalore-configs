# 1. Preparations

To install Datalore on-premise in AWS, you need the following tools installed on your machine:

1. [terraform version 0.14.10](https://www.terraform.io)
2. [AWS CLI](https://aws.amazon.com/cli/)

You also need to download this repository to your computer and [configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

# 2. Deploying AWS infrastructure

1. Go to the aws/terraform directory in this repository.
2. Change the parameters in `terraform.tfvars` file if needed. 
   It is important to use the name of your AWS key pair in `ssh_keypair`.

3. Execute:
    ```shell
    terraform init
    ```
4. Execute:
   ```shell
   terraform apply
   ```
   This command will print the following important information:
    * `datalore_ip` is the ip address of the machine where Datalore will be installed. This ip will be used for accessing Datalore.
    * `init_script` is the script which you will need to execute on the machine which the `terraform` script made for you.

# 3. Configuring Datalore

1. SSH to the machine with the ip (`datalore_ip`) from the previous step. Use `ubuntu` as a user and the private key of your AWS `ssh_keypair`.
   ```shell
   ssh -i <path_to_my_key> ubuntu@<datalore_ip>
   ```
2. Log into the Hub repository with the credentials that you received:
   ```shell
   sudo docker login registry.jetbrains.team -u <your_user>
   ```
3. Download the `datalore.sh` script:
   ```shell
   wget https://raw.githubusercontent.com/JetBrains/datalore-configs/develop/aws/datalore.sh
   chmod +x datalore.sh
   ```
4. Execute the `init_script` command from step 2.4 (eg `./datalore.sh <a_lot_of_params>`). This step may take some time.
   It installs Hub and prepares the default Datalore configs in the `/home/ubuntu/datalore` folder.

6. Execute:
   ```shell
   ./datalore.sh start-datalore
   ```
   This starts Datalore.


Now you have access to Datalore on `http://<datalore_ip>:8080` and Hub on `http://<datalore_ip>:8082`. 
Your admin account in Hub is `admin/changeme`. **Don't forget to change the password in Hub**.
Optionally, you can also modify the configs of Datalore in the `/home/ubuntu/datalore` folder.

# 4. (Optional) Setting up a hostname

If you don't want to access Datalore via ip and want to assign some human readable DNS name for it 
and add a load balancer with https, update the configuration:

1. Go to Hub `http://<datalore_ip>:8082/hub/services` (as admin user) 
   and replace the ip addresses in `Home URL`, `Base URLs`, and `Redirect URIs` with the DNS name for both Datalore and Hub services.

2. Go to the `/home/ubuntu/datalore/datalore.env` file and change the values of `HUB_PUBLIC_BASE_URL` and `FRONTEND_URL`.
   **Note:** The `/` symbol **is not recommended** at the end of `FRONTEND_URL`. For example, `https://my_address.com` is preferred over `https://my_address.com/`.
   
# 5. Starting/stopping

Use the following commands: 

* To stop Datalore and Hub:
```shell
./datalore.sh stop
```
* To start Datalore and Hub:
```shell
./datalore.sh start
```

* To check Datalore logs:
```shell
sudo docker logs datalore
```

* To check Hub logs:
```shell
sudo docker logs hub
```
