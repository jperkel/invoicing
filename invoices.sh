#! /bin/bash
# Script to handle freelance invoices
# (c) 2020 Jeffrey M. Perkel
#
# This script creates (if it does not exist) and manipulates a comma-separated values (CSV)-based list of invoices
#


# Default invoice database; you can specify an alternative location 
# as the last argument on the command line, eg ./invoices.sh unpaid mysheet2.csv.
# The `newfile` command creates a new database and saves its location in $configfile
# If no location is given at the command line, the location in $configfile is used.
default_csvfile=~/myinvoices.csv
configfile=~/invoices.config 

colnames="inv_no,inv_date,clientID,amt_billed,paid_date,amt_paid,taxes"

# functions
function usage() {
	echo -e "INVOICES.SH: Script to handle freelance invoices"
    echo -e "USAGE: $0 [COMMAND] <optional-params>"
    echo -e "\tCOMMANDS:"
    echo -e "\t\tadd\tAdd invoice"
    echo -e "\t\tclients\tList clientIDs"
    echo -e "\t\tdefault\tSet default invoice database <optional: invoice #>"
    echo -e "\t\tdelete\tDelete invoice <optional: invoice #>"
    echo -e "\t\tedit\tEdit invoice <optional: invoice #>"
    echo -e "\t\thelp\tDisplay help"
    echo -e "\t\tlist\tList all invoices"
    echo -e "\t\tnewfile\tCreate new invoices database <optional: filename>"
    echo -e "\t\tpay\tPay invoice <optional: invoice #>"
    echo -e "\t\treport\tDisplay summary for one client <optional: clientID>"
    echo -e "\t\tshow\tDisplay single invoice <optional: invoice #>"
    echo -e "\t\tsummary\tShow summary of all clients"
    echo -e "\t\ttaxes\tMark taxes paid"
    echo -e "\t\tunpaid\tList unpaid invoices"

}

function backupCSV {
    backup=$csvfile".bak"
    echo -e "\nBacking up database to: $backup\n"
    cp $csvfile $backup    
}

# confirm invoice number is valid
# input: $1: an invoice number
function validateInvNo {
    local inv_no=$1
    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number."
        exit 1
    fi 

    # limit search to exact matches (ie, 'grep 4' should only return 4, not 14, 24, 40, ...)
    match=$(cat $csvfile | sed "1d" | cut -f1 -d, | grep "^"$inv_no"$")
    if [ -z $match ]; then 
        echo "Invoice not found: $inv_no."
        exit 1
    fi
}

function doAdd {
    echo "Add invoice"
    echo -e "Invoices database: $csvfile\n"
    # next invoice number
    next=$(( $(cat $csvfile | sed "1d" | cut -f1 -d, | sort -n | tail -1) + 1 ))
    today=$(date +%Y-%m-%d)

    read -p "Invoice # [$next]: " inv_no
    if [ "$inv_no" == "" ]; then 
        inv_no=$next
    fi

    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number."
        exit 1
    fi 

    match=$(cat $csvfile | sed "1d" | cut -f1 -d, | grep $inv_no)
    if [ ! -z $match ]; then 
        echo "Invoice number in use: $inv_no."
        exit 1
    fi 

    read -p "Date [$today]: " d 
    if [ "$d" == "" ]; then 
        d=$today
    fi

    if [[ ! "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then 
        echo "Invalid date."
        exit 1
    fi

    read -p "ClientID: " client 

    while [[ "$amt" == "" ]]; do 
        read -p "Amount due: " amt 
    done 

    if [[ ! "$amt" =~ ^[0-9.]+$ ]]; then 
        echo "Invalid amount."
        exit 1
    fi 

    data=$(echo "$inv_no,$d,$client,$amt,NA,NA,NA")
    echo "" # insert newline
    printf "%s\n%s\n" $colnames $data | column -tx -s,

    read -p "Write record to file [y]: " answer 
    if [[ "$answer" == "" ]]; then
        answer="y"
    fi

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        # make a backup of the database...
        backupCSV

        echo "$inv_no,$d,$client,$amt,NA,NA,NA" >> $csvfile
#        cat $csvfile | \
#            awk -F, -v i="$inv_no" '{ if (NR==1 || $1==i) print $0 }' | column -tx -s,
        echo "Record added."
    else    
        echo "Record discarded."
    fi
}

function doClients {
    echo "Listing clientIDs"
    echo -e "Invoices database: $csvfile\n"

    cat $csvfile | sed '1d' | cut -f3 -d, | sort | uniq
}

# input: $1 (optional): filename
function doDefault {
    csvfile=$1
    if [[ "$csvfile" == "" ]]; then 
        read -p "Filename: " csvfile
    fi 

    if [ ! -e $csvfile ]; then 
        echo "File not found: $csvfile"
        echo -e "Use \`invoices init\` to create new invoice database."
        exit 1
    fi 

    local answer
    if [[ -e $configfile && ! $configfile == $csvfile ]]; then 
        echo "Default invoices database: $(cat $configfile)"
        read -p "Make $csvfile default database instead [n]: " answer 
        if [[ "$answer" == "" ]]; then    
            answer="n"
        fi 

        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            cp $configfile $configfile".bak"
            echo $csvfile > $configfile
        fi
    else 
        echo $csvfile > $configfile 
    fi

}

# input: $1 (optional): invoice number
function doDelete {
    echo "Delete invoice"
    echo -e "Invoices database: $csvfile\n"

    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s,

    local answer
    read -p "Delete this invoice? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        # make a backup of the database...
        backupCSV

        cat $csvfile | \
            awk -F, -v i="$inv_no" '{ if (NR==1 || $1 != i) print $0 }' > tmp && mv tmp $csvfile

        cat $csvfile | column -tx -s,
        echo "Invoice deleted."
    fi
}

# input: $1 (optional): invoice number
function doEdit {
    echo "Edit invoice"
    echo -e "Invoices database: $csvfile\n"

    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s,

    local answer
    read -p "Edit this invoice? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        inv_dt=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f2 -d,)
        client=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f3 -d,)
        amt_due=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f4 -d,)
        pd_dt=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f5 -d,)
        amt_pd=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f6 -d,)
        taxes=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f7 -d,)

        read -p "Inv. date [$inv_dt]: " id
        read -p "ClientID [$client]: " c
        read -p "Amt. due [$amt_due]: " ad 
        read -p "Paid date [$pd_dt]: " pd
        read -p "Amt. paid [$amt_pd]: " ap 
        read -p "Taxes [$taxes]: " t 

        if [ "$id" != "" ]; then
            inv_dt=$id
        fi 

        if [ "$c" != "" ]; then
            client=$c
        fi 

        if [ "$ad" != "" ]; then
            amt_due=$ad
        fi 

        if [ "$pd" != "" ]; then
            pd_dt=$pd
        fi 

        if [ "$ap" != "" ]; then
            amt_pd=$ap
        fi 

        if [ "$t" != "" ]; then
            taxes=$t
        fi 


        if [[ ! "$amt_due" =~ ^[0-9.]+$ ]]; then 
            echo "Invalid amount due."
            exit 1
        fi 

        if [[ ! "$amt_pd" =~ ^[0-9.]+$ && "$amt_pd" != "NA" ]]; then 
            echo "Invalid amount paid."
            exit 1
        fi 

        if [[ ! "$inv_dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then 
            echo "Invalid invoice date."
            exit 1
        fi

        if [[ ! "$pd_dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$pd_dt" != "NA" ]]; then 
            echo "Invalid paid date."
            exit 1
        fi

        # make a backup of the database...
        backupCSV
    
        s=$(echo "$inv_no,$inv_dt,$client,$amt_due,$pd_dt,$amt_pd,$taxes")
        cat $csvfile | \
            awk -F, -v i="$inv_no" -v s="$s" '{ if ($1 == i) print s; else print $0 }' > tmp && mv tmp $csvfile

        echo -e "\n"
        cat $csvfile | \
            awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
            column -tx -s,

        echo -e "\nRecord updated."
    fi
}

function doList {
    echo "List invoices"
    echo -e "Invoices database: $csvfile\n"

    cat $csvfile | column -tx -s,
}

# input: $1 (optional): filename
function doNewDb {
    echo "Create new invoice database"

    csvfile=$1
    if [[ "$csvfile" == "" ]]; then 
        read -p "Filename [$default_csvfile]: " csvfile

        if [[ "$csvfile" == "" ]]; then   
            csvfile=$default_csvfile
        fi
    fi 

    local answer="y"
    if [ -e $csvfile ]; then
        read -p "File $csvfile already exists. Do you want to overwrite it [n]: " answer
    fi 

    if [[ "$answer" == "" ]]; then  
        answer="n"
    fi

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo $colnames > $csvfile 
        echo "File $csvfile created."

        doDefault $csvfile 
    else 
        echo "File creation cancelled."
    fi 
}

# input: $1 (optional): invoice number
function doPay {
    echo "Pay invoice"
    echo -e "Invoices database: $csvfile\n"

    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s,

    local answer
    read -p "Mark this invoice paid? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        today=$(date +%Y-%m-%d)
        pd=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f6 -d,)
        due=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f4 -d,)

        # see https://stackoverflow.com/questions/16529716/save-modifications-in-place-with-awk
        if [[ "$pd" == "NA" || "$pd" -ne "$due" ]]; then 
            read -p "Amount paid [$due]: " amt 
            read -p "Date [$today]: " d 

            if [[ "$amt" == "" ]]; then
                amt=$due
            fi 

            if [[ "$d" == "" ]]; then
                d=$today 
            fi 

            if [[ ! "$amt" =~ ^[0-9.]+$ ]]; then 
                echo "Invalid payment amount."
                exit 1
            fi 

            if [[ ! "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then 
                echo "Invalid payment date."
                exit 1
            fi

            # make a backup of the database...
            backupCSV

            cat $csvfile | \
                awk -F, -v OFS="," -v i="$inv_no" -v a="$amt" -v d="$d" '{ if ($1==i) { $6=a; $5=d } print $0 }' > tmp && mv tmp $csvfile
            cat $csvfile | \
                awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
                column -tx -s,

            echo -e "Invoice paid.\n"

        else 
            echo "Invoice already paid."
        fi
    fi 
}

# input: $1 (optional): clientID
function doReport {
    echo "Invoice report"
    echo -e "Invoices database: $csvfile\n"

    if [ "$#" -lt 1 ]; then
        read -p "ClientID: " client 
    else 
        client=$1
    fi 

    match=$(cat $csvfile | sed "1d" | cut -f3 -d, | sort | uniq | grep $client)
    if [ -z $match ]; then 
        echo "No records found for client: $client."
        exit 1
    fi 

    echo -e "\nClientID:\t$client"
    cat $csvfile | \
        awk -F, -v client="$client" '$3==client { COUNT++; BILLED += $4; PAID += $6; DUE += $4-$6 } END \
            { if (COUNT == 0) print "No invoices found.\n" 
            else print "No. invoices:\t"COUNT,
                "\nTotal billed:\t"BILLED,
                "\nTotal paid:\t"PAID,
                "\nAmount due:\t"DUE,
                "\n" 
            }'
    echo "Invoices:"
    # this version of the code shows unpaid balances
    # cat $csvfile | \
    #     awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
    #     awk -F, -v OFS="," 'NR==1 { $(NF+1)="past_due"; print $0 } 
    #                         NR>1 { if ($6 != $4) print $0,$4-$6; else print $0 }' | \
    #     column -tx -s,

        # this version of the code calculates the number of days an invoice is past-due.
    cat $csvfile | \
        awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
        awk -F, -v OFS="," -v today=$(date +%s) 'NR==1 { $(NF+1)="days_past_due"; print $0; } \
                NR>1 { if ($6 < $4 || $6 == "NA") { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; $8=(today-inv_dt)/86400 }; print $0 }' | \
        column -tx -s,
}

# input: $1 (optional): invoice number
function doShow {
    echo "Show invoice"
    echo -e "Invoices database: $csvfile\n"

    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s,
}

function doSummary {
    echo "Client summary"
    echo -e "Invoices database: $csvfile\n"

    # for each client, tally # of invoices, amt billed, amt paid, balance due; write the data out as a CSV
    data=$(cat $csvfile | sed "1d" | \
            awk -F, '{ count[$3]++; billed[$3] += $4; paid[$3] += $6; unpaid[$3] += $4-$6; } END \
            { for (c in count) print c","count[c]","billed[c]","paid[c]","unpaid[c] }')
    headings=$(echo "clientID,invoices,billed,paid,unpaid")
    # add headings to the data and format
    printf "%s\n%s\n" $headings $data | column -tx -s,

    # count total # of invoices, total amount billed, paid and unpaid
    echo "$(printf "%s\n" $data | awk -F, '{count += $2; sum += $3; paid += $4; unpaid += $5 } END \
    {print "\n\tNum. invoices:\t"count"\n\tTotal billed:\t$"sum"\n\tTotal paid:\t$"paid"\n\tBalance due:\t$"unpaid"\n" }')"
}

function doTaxes {
    echo "Taxes"
    echo -e "Invoices database: $csvfile\n"

    cat $csvfile | \
        awk -F, '{ if (($7 == "NA" && $6 != "NA") || NR==1) print $0 }' | \
        column -tx -s,

    taxable=$(cat $csvfile | awk -F, '$7 == "NA" && $6 != "NA" { INC += $6; } END { print "Untaxed income: " INC }')
    echo -e "\n$taxable"

    local answer 
    read -p "Mark taxes paid for these invoices? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        # make a backup of the database...
        backupCSV

        read -p "Value for taxes field: " taxes

        cat $csvfile | \
            awk -F, -v OFS="," -v t="$taxes" '{ if ($7=="NA") { $7=t } print $0 }' > tmp && mv tmp $csvfile
        cat $csvfile | column -tx -s,
        echo -e "Record updated.\n"
    fi     
}

function doUnpaid {
    echo "Outstanding invoices:"
    echo -e "Invoices database: $csvfile\n"

    # this version of the code shows the outstanding balance
#    cat $csvfile | \
#        awk -F, -v OFS="," 'NR==1 { $(NF+1)="bal_due"; print $0 } NR>1 { if ($6 != $4) print $0,$4-$6 }' | \
#        column -tx -s,

    # this version of the code calculates the number of days an invoice is past-due.
    cat $csvfile | \
        awk -F, -v OFS="," -v today=$(date +%s) 'NR==1 { $(NF+1)="days_past_due"; print $0; } NR>1 { if (($6 < $4) || ($6 == "NA")) { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; print $0,(today-inv_dt)/86400 } }' | \
        column -tx -s,

    echo -e "\n\tUnpaid summary:"
    cat $csvfile | \
        awk -F, '{ a[$3] += $4-$6; DUE+=$4-$6; } END { for (i in a) if (a[i] != 0) print "\t"i": $"a[i]; print "\n\tTotal due: $"DUE,"\n" }'
}

function main {
    local answer
    # if the last cmdline argument is a csv file, use that as the database
    # see https://unix.stackexchange.com/questions/444829/how-does-work-in-bash-to-get-the-last-command-line-argument
    match=$(echo ${!#} | grep "\.csv$")
    if [ $match ]; then
        csvfile=$match
        # remove the filename from the arg list
        # see https://stackoverflow.com/questions/37624085/delete-final-positional-argument-from-command-in-bash
        set -- "${@: 1: $#-1}"

    elif [ -e $configfile ]; then
        csvfile=$(head -n 1 $configfile)
    fi 

    if [ -z $csvfile ]; then
        echo -e "\nError: No invoices database found. Use \`invoices newfile\` to create one.\n"
        usage 
        exit 1
    fi 

    if [ "$#" -lt 1 ]; then
        echo "Error: Command required."
        usage
        exit 1
    fi 

    command=$1
    shift 

    case $command in
    "add")
        doAdd $1
        ;;

    "clients")
        doClients $1
        ;;

    "default")
        doDefault $match
        ;;

    "delete")
        doDelete $1
        ;;

    "edit")
        doEdit $1
        ;;

    "help")
        usage 
        ;;

    "list")
        doList $1
        ;;

    "newfile")
        doNewDb $match
        ;; 

    "pay")
        doPay $1
        ;;

    "report")
        doReport $1 
        ;;

    "show")
        doShow $1
        ;;

    "summary")
        doSummary $1
        ;;

    "taxes")
        doTaxes $1
        ;;

    "unpaid")
        doUnpaid $1
        ;;

    *)
        echo "Error: command not recognized"
        usage
        ;;
    esac
}

main $@