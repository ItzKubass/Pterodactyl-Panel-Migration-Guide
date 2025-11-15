# Pterodactyl Panel Migration: A Complete Guide

This guide explains the full manual migration process **and also
includes an optional fully automated migration method** using a
one-click script.

## 🚀 Automated Migration (Optional)

If you prefer a fully automated approach, you can use an
**Auto‑Migration script** that performs:

-   Panel + Wings migration
-   Automatic backup
-   File transfer
-   Database import
-   Permissions fixing
-   Logging to a file
-   Automatic rollback on failure

This is the fastest and safest method for full server moves.

------------------------------------------------------------------------

## Manual Migration Guide

Migrating a Pterodactyl panel from one machine to another can be a
daunting task, but with the right steps, it becomes a smooth and
straightforward process. This guide will walk you through migrating both
the Pterodactyl panel and Wings to a new server, covering how to back
up, transfer, and configure everything to ensure a successful migration.

## Prerequisites

Before starting the migration process, ensure the following:

-   You have root access to both the old and new machines
-   You have MySQL installed on both servers
-   Both servers have the required dependencies for running Pterodactyl
-   The new server meets the Pterodactyl system requirements

## Step 1: Backup the Pterodactyl Panel

To migrate your panel, start by backing up essential components on the
old machine.

### 1.1 Backup the .env File

The `.env` file located in `/var/www/pterodactyl` contains sensitive
environment variables such as your `APP_KEY`.\
This file is essential for decrypting data and must be transferred to
the new server.

``` bash
cd /var/www/pterodactyl
```

Ensure the backup location is secure, as this file contains sensitive
information.

### 1.2 Backup the Database

Export the Pterodactyl database (assumed to be named `panel`):

``` bash
mysqldump -u root -p --opt panel > /var/www/pterodactyl/panel.sql
```

This creates `panel.sql`, which you will later import on the new server.

## Step 2: Set Up Pterodactyl on the New Server

Install a fresh instance of the Pterodactyl panel before importing your
data.

### 2.1 Install the Pterodactyl Panel

Follow the official installation guide to complete the required setup.

## Step 3: Migrate the Database

### 3.1 Transfer the `panel.sql` File

Use `scp` or another method to transfer the SQL file from the old
server.

### 3.2 Import the Database

``` bash
mysql -u root -p panel < /var/www/pterodactyl/panel.sql
```

Verify that the database name matches your configuration.

## Step 4: Restore the .env File

Transfer the `.env` file to:

    /var/www/pterodactyl

This file contains the application key used for decryption and must be
restored properly.

## Step 5: Migrating Wings

### 5.1 Install Wings

Follow the Wings installation guide on your new server.

### 5.2 Transfer Volumes

Game server data resides in:

    /var/lib/pterodactyl/volumes/

Copy these volumes to the same directory on the new machine.

## Step 6: Update Allocations

The new machine will likely have a new IP address.

### 6.1 Get the New IP Address

``` bash
hostname -I | awk '{print $1}'
```

### 6.2 Update the Database with the New IP

``` bash
mysql -u root -p
USE panel;
UPDATE allocations SET ip = 'newiphere' WHERE ip = 'oldiphere';
exit
```

## Conclusion

You've successfully migrated your Pterodactyl panel and Wings to a new
server.\
This guide includes both the detailed manual process and an optional
automated method to simplify and speed up migration tasks.

If executed carefully, your migration will complete with minimal
downtime and without data loss.
