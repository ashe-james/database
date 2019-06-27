#  Variables

ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/db

STAGE=$HOME

echo 'Database FQDN:'
read FQDN
echo ''
SID=$( echo $FQDN | cut -d '.' -f1 | tr '[:upper:]' '[:lower:]' )
DOMAIN=$( echo $FQDN | cut -d '.' -f2- | tr '[:upper:]' '[:lower:]' )
echo Database SID: $SID
echo Database DOMAIN: $DOMAIN
echo ''
echo 'Memory (in MB):'
read MEMORY
echo ''
PASSWORD=$( < /dev/urandom tr -dc A-Za-z_+=.: | head -c1 )$( < /dev/urandom tr -dc A-Za-z0-9_+=.: | head -c17 )
echo 'Power User (SYS/SYSTEM/DBSNMP) Password: '$PASSWORD
echo ''

#  database

PATH=$ORACLE_HOME/bin:$PATH

CHANGEARRAY=(
    gdbName=$SID.$DOMAIN
    sid=$SID
    databaseConfigType=SI
    templateName=General_Purpose.dbc
    sysPassword=$PASSWORD
    systemPassword=$PASSWORD
    dbsnmpPassword=$PASSWORD
    datafileDestination=+DATA
    recoveryAreaDestination=+FRA
    storageType=ASM
    diskGroupName=DATA
    recoveryGroupName=FRA
    characterSet=AL32UTF8
    totalMemory=$MEMORY
)

cp $ORACLE_HOME/assistants/dbca/dbca.rsp $STAGE
DB_RSP=$STAGE/dbca.rsp

for C in "${CHANGEARRAY[@]}"; do 
        O=$( echo $C | cut -d '=' -f1 )=
        U=$( echo $C | sed 's/\//\\\//g' )
	if ( ! grep -q "^$U" $DB_RSP ); then
        	sed -i "s/$O/$U/g" $DB_RSP
	fi
done

$ORACLE_HOME/bin/dbca -createDatabase -silent -responseFile $DB_RSP

rm $DB_RSP