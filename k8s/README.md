To install Datalore on-premise, first install and configure Hub, which provides a single point of entry for user management. The procedures below describe both stages of the process.

NB: it is assumed that shell commands are executed in repository root directory (one containing `README.md`).

# 1. Install Hub
If you have already installed Hub, skip this part and go to the __Configuration of Hub__ section.
You can find more details about the Hub installation process [here](https://hub.docker.com/r/jetbrains/hub).
1. Configure Hub persistent volumes: replace `emptyDir` values in `volumes` section of `./hub/statefulSet.yaml` file
   to volumes available in your kubernetes cluster.

   NB: If you leave the default configuration, you will __lose ALL DATA__ after the next Hub restart.
1. Run <!-- capitalized?-->Hub via command:
    ```
    kubectl apply -k ./hub/
    ```
1. It is assumed later that you can access Hub at `http://localhost:8082`. For it to work you may need to forward the port running the following command:
   ```
   kubectl port-forward --address 0.0.0.0 service/hub 8082
   ```
1. Check the container output using the following command:
   ```
   kubectl logs service/hub
   ```
   It should contain a line like this:
   `JetBrains Hub 2020.1 Configuration Wizard will listen inside the container on {0.0.0.0:8080}/
   after start and can be accessed by this URL:
  [http://<put-your-docker-HOST-name-here>:<put-host-port-mapped-to-container-port-8080-here>/?wizard_token=pPXTShp4NXceXqGYzeAq]`.
   Copy the `wizard_token` to the clipboard.
1. Go to `http://localhost:8082/` and insert the token from previous step into the __Token__ field. Click the __Log in__ button.
1. Click the __Set Up__ link.
1. Next, you need a URL (referred to as `HUB_ROOT_URL` later) to access Hub from Datalore. Consider the following:
   - This URL must be accessible from both the cluster pods and the browser (by the end users of your Datalore installation).
   - The URL must point to the `/` path of your Hub installation, i.e. `http://127.0.0.1:8080/` inside the container where Hub is launched (by default, it's pod `hub-0`).
   - How you set up your cluster to serve such a URL depends on the specifics of your cluster configuration.
1. In __Base URL__, specify `HUB_ROOT_URL`. Don't change the __Application Listen Port__ setting.
1. Click the `Next` button.
1. Configure the admin account (set the admin password).
1. Click the `Finish` button and wait for the Hub startup.
## 1.1 Configure Hub
Go to `HUB_ROOT_URL` and log into Hub via admin account.
### 1.1.1 Configure Datalore service
1. Here, you need another URL (referred to as `DATALORE_ROOT_URL` later) to access Datalore from a browser. Consider the following:
    - This URL must be accessible from the browser (by the end users of your Datalore installation).
    - The URL must point to the `/` path of your Datalore installation, i.e. `http://127.0.0.1:8080/` inside the container where Datalore will be launched (by default, it's pod `datalore-on-premise-0`).
    - How you set up your cluster to serve such a URL depends on the specifics of your cluster configuration.
1. Go to Services (`${HUB_ROOT_URL}/hub/services`) and click the __New service__ button. Use the name _datalore_ and `DATALORE_ROOT_URL` as __Home URL__.
1. Copy the `ID` field value – it is used when configuring Datalore (`$HUB_DATALORE_SERVICE_ID` property).
1. Click the __Change...__ button near the __Secret__ label. Retain the generated secret somewhere – it will be used when configuring Datalore
   (`$HUB_DATALORE_SERVICE_SECRET` property). Click the __Change secret__ button.
1. Insert `DATALORE_ROOT_URL` into the __Base URLs__ field.
1. Insert line `/api/hub/openid/login` into the __Redirect URIs__ field.
1. Click the __Trust__ button in the upper-right corner.
1. Click the __Save__ button.
### 1.1.2 Create Hub token
1. Go to Users (`${HUB_ROOT_URL}/hub/users`).
1. Click your admin user's name.
1. Go to the `Authentication` tab.
1. Click the __New token...__ button.
1. Add Hub and Datalore into __Scope__. You can use any __Name__. Click the __Create__ button.
1. Remember the token. It will be used when configuring Datalore (`$HUB_PERM_TOKEN` property).
### 1.1.3 Force email verification
Datalore uses user emails from Hub, so it is recommended to force email verification in Hub.
Users with unverified emails will not be able to use Datalore.
#### 1.1.3.1 Configure the SMTP server
1. Go to SMTP (`${HUB_ROOT_URL}/hub/smtp-settings`).
1. Click the __Configure SMTP server...__ button.
1. Configure your SMTP server parameters.
1. Click the __Save__ button.
1. Click the __Enable notifications__ button.
1. (Optional) To make sure your configuration is working, click the __Send Test message__ button.
#### 1.1.3.2 Enable email verification
1. Go to Auth Modules (`${HUB_ROOT_URL}/hub/authmodules`).
1. Open the __Common settings__ page.
1. Enable the __Email verification__ option.
1. Click the __Save__ button.
#### 1.1.3.3 Set and verify an admin user email
1. Go to Users (`${HUB_ROOT_URL}/hub/users`).
1. Click your admin user's name.
1. Set email in the `Email` field.
1. Click the `Save` button.
1. Click `Send verification email` link.
1. Find verification email in your inbox and click `Verify email address` button.
### 1.1.4 (Optional) Ban guest user
Skip this step if you need a guest user.
1. Go to Users (`${HUB_ROOT_URL}/hub/users`).
1. Select a guest user.
1. Click the __Ban__ button.
### 1.1.5 (Optional) Enable auth modules
Go to Auth Modules (`${HUB_ROOT_URL}/hub/authmodules`). Here, you can add/remove different auth modules
(e.g. Google auth, GitHub auth, LDAP, etc.).

# 2. Install Datalore
To run Datalore, you need Kubernetes (we have checked version `1.17.6`, but other versions should also work).
## 2.1 Configuration
To simplify the configuration process, the Kubernetes config is split into small chunks and assembled with 
the Kustomize tool (`-k` flag of `kubectl`).
Edit several files in the `datalore/configs` directory to configure your Datalore installation:
### 2.1.1 `user_config.yaml`
Editing this file is __mandatory__ to get everything working. The file has the following fields:
#### 2.1.1.1 Required parameters:
- `FRONTEND_URL` – URL by which Datalore can be accessed (`DATALORE_ROOT_URL`). It is used to generate links.  
  __Note:__ Make sure the URL does not contain a trailing slash.
- `HUB_PUBLIC_BASE_URL` – base public (should be accessible via browser) URL of your Hub installation (`${HUB_ROOT_URL}/hub` from the __Install Hub__ section, i.e. `https://hub.your.domain/hub`).
- `HUB_INTERNAL_BASE_URL` – base internal (should be accessible from datalore pod) URL of your Hub installation (in most cases could be equal to `${HUB_PUBLIC_BASE_URL}`).
- `HUB_DATALORE_SERVICE_ID` – ID of the Datalore service in Hub (see __Configure Datalore service__ section).
- `HUB_DATALORE_SERVICE_SECRET` – token of the Datalore service in Hub (see the __Configure Datalore service__ section).
- `HUB_PERM_TOKEN` – Token for accessing Datalore and Hub scopes (see the __Create Hub token__ section).
  
- `DEFAULT_INSTANCE_TYPE_ID` — ID of the instance type that will be used by default (for more information, see `agents_config.yaml`).
- `PASSWORD_SECRET` – additional hash salt used to encrypt user passwords and prevent rainbow table attacks in case of a database leak. 
  Can be any string.
#### 2.1.1.2 Optional parameters:
 `MAIL_ENABLED` – set it to `"true"` in order to enable Datalore to send emails (welcome emails, sharing invitations, etc.). 
  When set to `"true"`, requires the following parameters:
  - `MAIL_SENDER_EMAIL` – sender's email.
  - `MAIL_SENDER_NAME` – sender's name.
  - `MAIL_SENDER_USERNAME` – username of SMTP user.
  - `MAIL_SENDER_PASSWORD` – password of SMTP user.
  - `MAIL_SMTP_SERVER` – SMTP server host.
  - `MAIL_SMTP_PORT` – SMTP server port.
### 2.1.2 `db_config.yaml`
This config file is used to configure PostgreSQL connection from Datalore. There is one field to override:
- `ROOT_PASSWORD` – root user's password. The database can be accessed on port `5432` with the username `postgres` and this password.
### 2.1.3 `volumes_config.yaml`
This config file is used to mount volumes for persisting Datalore's data between restarts. If you leave the default configuration, you will __lose ALL DATA__ after the next Datalore restart. The config has two Kubernetes volumes described:
- `storage` – this volume contains workbook data, such as attached files.
- `postgresql-data` – this volume contains PostgreSQL database data.
### 2.1.4 `agents_config.yaml`
This config file is used to define agent types (such as Basic and Large machines in the cloud version of Datalore).
It has the following schema:
```yaml
k8s:
  instances:
    - id: <Inique instance ID>
      label: <Instance name>
      description: <Short description of what the instance is>
      minAllowed: <Minimum number of instances to be preserved in the pool>
      maxAllowed: <Maximum number of instances to be preserved in the pool>
      yaml:
        <Kubernetes config of Pod to be used for the instance>
    - id: <Another type with the same schema as above>
      ...
```
The `minAllowed` and `maxAllowed` fields are used to configure the number of pre-created instances, which will speed up the process of
starting up notebooks.  
__Note:__ Make sure that one of the IDs defined in the list of instances matches the `DEFAULT_INSTANCE_TYPE_ID` variable from `user_config.yaml`. That instance 
will be used as a default option when creating a notebook.
Besides changing the descriptive fields (all except `yaml`), you may want to customize the following pod description fields:  
- `spec -> containers -> image` – you can build a custom Docker image on top of the default one to customize your environment (i.e. install some
  package from `apt` to be available in your notebooks, or set up a custom Python environment by pre-installing the required libraries).
- `spec -> containers -> resources` – you can tune the resources required by the agent's pod to match your needs and capabilities.
### 2.1.5 `images_config.yaml`
This config file is used to define Datalore and PostgreSQL container images. Most likely, you will need to change this only to update your installation
with <!--'never' presumably a typo--> newer versions of on-premises images.
### 2.1.6 `logback.xml`
This is the Logback configuration file that will be used to collect logs from Datalore and agents. We have provided the default one, which just prints them to `stdout`, but you can configure it any way you like.  
More information on how to configure Logback is available in [the official documentation](http://logback.qos.ch/manual/configuration.html).
## 2.2 Docker Hub token
Create a secret to pull images from a private repository:
`kubectl create secret docker-registry regcred --docker-username=datalorecustomer --docker-password=<datalore token>`
# 3. Run Datalore
## Start
`kubectl apply -k ./datalore/`
## Stop
`kubectl delete -k ./datalore/`
