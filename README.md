# Introduction
This repo will help you create a minimal ISO file with Ubuntu 22.04 LTS under MacOS.
The build image can either be an **arm64** or **amd64** iso.

## Structure
The preseed folder contains two files:
- *grub.cfg* Grub configuration.
- *user-data* preseed file. 

# Build an ISO Image
1. Set the **hostname**, **username** and **password** you want the server to
   have in the *user-data* file.  To get a seeded password execute the
   follwoing command
```
make password
```
   Copy the password into the *user-data* file.
   
2. If you have a ssh-public-key you want to deploy to the default user, put it
   in the appropirate section in the *user-data* file.
```
    authorized-keys:
      - ssh-rsa myfancykey
    allow-pw: yes
```

3. Create the ISO for your architecture.
```
make ARCH=arm64|amd64
```

