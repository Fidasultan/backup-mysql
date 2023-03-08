This script works as follows:

It sets the MySQL username, password, and backup path.

It creates the backup path if it does not exist.

It retrieves a list of all databases.

It creates a new backup directory for the current day.

If a full backup has not been performed for today yet, it performs a full backup of all databases and saves it as a compressed file in the daily backup directory.

If an incremental backup has not been performed for the current hour, it creates a new incremental backup directory for the hour and performs an incremental backup of all databases. If an incremental backup directory already exists for the hour, it skips the incremental backup.

If a full backup or incremental