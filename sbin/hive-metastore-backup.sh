


dbhost="$1"
dbport="$2"
dbname="$3"

( mysqldump -u hive -p -h $dbhost -P $dbport --opt $dbname > $dbname-$host-backup.sql )

(  mysqldump -u hive -p -h $dbhost -P $dbport --skip-add-drop-table --no-data $dbname > hive-$dbhost-schema-1.2.1.mysql.sql )


