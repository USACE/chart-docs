# Steps for setting up Docker container within a Virtual Machine

## Some items to consider
Many of the commands may need to be run as an administrator, in the case of Ubuntu that will require the ‘sudo’ command in front of the rest of the command

PgAdmin appears to cause problems by using port 80, recommend using DBeaver



## Step 01 - Install Docker on Ubuntu

Use the following link (note: this might change and it would be better to search via Google)
https://docs.docker.com/engine/install/ubuntu/

Recommended method is via the Install using the apt repository

Docker Desktop cannot be installed in a virtual machine. If you want an GUI for Docker use portainer.io

1. Run portainer.io from the terminal `docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer`
2. Enter `http://localhost:9000/` into your Web Browser
3. Create an account
4. Go to `Home` on the upper left side of the menu
5. Click the local environment to access the Images, Containers, Volumes and more

Commands to run:
```
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
```


## Step 02 - Edit Hosts File

1. Navigate to ./etc/hosts file
2. Open a terminal in that location and run `sudo open hosts` this will open the host file with the default text editor
3. Update the hosts file with the following:
    * `127.0.1.1 kubernetes.docker.interal`
    * `127.0.1.1 dev2.crrel.mil`

This is needed because the physical machine is `127.0.0.1 dev2.crrel.mil` and the Virtual Machine needs to an additional IP address

Commands to run:
```
sudo open hosts
```


## Step 03 - Local Development Docker

1. Download the appropriate branch of `local-dev-docker repo`
2. Copy the `kdata` folder provided into the `local-dev-docker` folder
3. Add `"extrahost"` to each container name in your docker-compose.yaml file: `"host.docker.internal:host-gateway"` or copy the files
4. Run the following command: `sudo docker compose up`

Commands to run:
```
sudo docker compose up
```


## Step 04 - Screening API

1. Download the appropriate branch of `screening-tool-api-support`
2. Create `tests` folder and place `pk.pem` file in the tests folder from step 1, `./tests/pk.pem`
3. Add `"extrahost"` to each container name in your docker-compose.yaml file: `"host.docker.internal:host-gateway"` or copy the files
4. Run the command: `sudo docker compose up -d`
5. Run the command: `sudo docker exec -it STAPI_DEV bash`
6. Run the command: `go run .`
7. If successfully you will see text for the Echo Framework

Commands to run:
```
sudo docker compose up -d
sudo docker exec -it STAPI_DEV bash
go run .
```


## Step 05 - Screening UI

1. Download appropriate branch of `screening-tool-ui-main`
2. Create a `.devcontainer` file and place `local.env` in the folder in step 1
3. Add `"extrahost"` to each container name in your docker-compose.yaml file: `"host.docker.internal:host-gateway"` or copy the files
4. Run the command: `sudo docker compose up -d`
5. Run the command: `sudo docker exec -it STUI_DEV sh`
6. Run the command: `yarn install`
7. Run the command: `yarn run dev`

Commands to run:
```
sudo docker compose up -d
sudo docker exec -it STUI_DEV sh
yarn install
yarn run dev
```



## Step 06 - Database Setup
A word of caution, when I attempted to install PgAdmin, Apache was installed and uses port 80, which is required by other services. For this tutorial it is recommended to use DBeaver Community Edition
DBeaver Community website: https://dbeaver.io/

### Step 01 - Install DBeaver Community Edition
To download and install: https://dbeaver.io/download/

Use any of the install methods you prefer. Only use one!

#### Debian Package Install
1. Download the .deb package
2. Navigate to the directory with the .deb package
3. Run the command: `sudo dpkg -i <package_name>`

#### Snap Install
1. Run the command: `sudo snap install dbeaver-ce`

#### Flatpak Install
1. Run the command: `flatpak install flathub io.dbeaver.DBeaverCommunity`

### Step 02 - Create the database connection
1. Open DBeaver
2. Create a new database connection of PostgreSQL type
3. Make sure the following fields are set as follows:
    * Connect by: Host
    * Host: localhost
    * Port: 25432
    * Database: gis
    * Authentication: Database Native
    * Username: <username>
    * Password: <password>

4. Click "Test Connection"
5. Click "Ok"

### Step 03 - Load the SQL Script
create.sql is in scripts folder for the screening-tool-api-support

In DBeaver:
1. SQL Editor -> New SQL Script
2. SQL Editor -> Import SQL script -> Load the create.sql file
3. SQL Editor -> Execute SQL query



## Step 07 - Open the Screening Tool
1. In your browser navigate to: `https://dev2.crrel.mil/screening-tool`
2. Enjoy and happy programming! :D


