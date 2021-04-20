# 1. Preparations

To install Datalore on-premise in AWS, you will need some tools installed on your machine:

1. [terraform](https://www.terraform.io)
2. [AWS CLI](https://aws.amazon.com/cli/)

You also will need to download this repository to your computer and [confugire AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

# 2. Deploying AWS infrastructure

1. Go to the aws/terraform directory in this repository
2. Change parameters in `terraform.tfvars` file if needed. 
   It is important to set the name of your aws keypair in `ssh_keypair`.
   Also don't forget to change `name_prefix`, due to AWS limitation it should be unique accross all AWS region.

3. Execute
    ```shell
    terraform init
    ```
4. Execute:
   ```shell
   terraform apply
   ```
   This command will prin wery important information:
    * `datalore_ip` is the ip address of machine where datalore will be installed. This ip will be used for accessing datalore.
    * `init_script` is the script which you will need to execute on machine which terraform script made for you.

# 3. Configuring datalore

1. SSH to the machine with ip `datalore_ip` from previous step. Use user `ubuntu` and private part of your AWS `ssh_keypair`.
   ```shell
   ssh -i <path_to_my_key> ubuntu@<datalore_ip>
   ```
2. Login into hub repository with credentials that you received:
   ```shell
   sudo docker login registry.jetbrains.team -u <your_user>
   ```
3. Download `datalore.sh` script:
   ```shell
   wget https://raw.githubusercontent.com/JetBrains/datalore-configs/develop/aws/datalore.sh
   chmod +x datalore.sh
   ```
4. Execute command `init_script` (eg `./datalore.sh <a_lot_of_params>>`) from 2.4 step. This step could take some time.
5. Now you will have installed hub and prepared default datalore configs in `/home/ubuntu/datalore` folder.
6. Execute
   ```shell
   ./datalore.sh start-datalore
   ```
   It should start datalore.


Now you should be able to access datalore on `http://<datalore_ip>:8080` and hub on `http://<datalore_ip>:8082`. 
You admin account in hub is `admin/changeme`. **Don't forget to change the password in hub**.
You also could modify configs of datalore in `/home/ubuntu/datalore` folder if you want.

# 4. (Optional) Setting up hostname

Probably you will not want to access datalore via ip and will want to assign some human readable DNS name for it 
and to add load balancer with https.
In such case you will need to update configuration:

1. Go to hub `http://<datalore_ip>:8082/hub/services` (as admin user) 
   and replace ip addresses in `Home URL`, `Base URLs`, `Redirect URIs` by DNS name for both Datalore and Hub services.

2. Go to file `/home/ubuntu/datalore/datalore.env` and change values of `HUB_PUBLIC_BASE_URL` and `FRONTEND_URL`.
   Note: `FRONTEND_URL` **should not ends** with `/` symbol, eg it should be like `https://my_address.com`, not like `https://my_address.com/`
   
# 5. Starting/stopping

You could stop Datalore and Hub with command
```shell
./datalore.sh stop
```
You could start Datalore and Hub with command
```shell
./datalore.sh start
```

You could check logs of Datalore with command:
```shell
sudo docker logs datalore
```

You could check logs of Hub with command:
```shell
sudo docker logs hub
```
