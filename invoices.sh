#! /bin/bash
# Script to handle freelance invoices
# (c) 2020 Jeffrey M. Perkel
#
# This script creates (if it does not exist) and manipulates a comma-separated values (CSV)-based list of invoices
#


# Default invoice database; you can specify an alternative location 
# as the last argument on the command line, eg ./invoices.sh unpaid mysheet2.csv.
# The `newfile` command creates a new database and saves its location in $CONFIG_FILE
# If no location is given at the command line, the location in $CONFIG_FILE is used.
DEFAULT_INVOICE_FILENAME=myinvoices.csv
CONFIG_FILE=~/invoices.config 

colnames="inv_no,inv_date,clientID,amt_billed,paid_date,amt_paid,taxes"

# functions
function usage() {
    echo -e "\nINVOICES.SH: Script to handle freelance invoices"
    echo -e "USAGE: $(basename $0) [COMMAND] <optional-params>"
    echo -e "\tCOMMANDS:"
    echo -e "\t\tadd\tAdd invoice"
    echo -e "\t\tclients\tList clientIDs"
    echo -e "\t\tdefault\tSet default invoice database <optional: filename>"
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
    backup=$INVOICE_FILE".bak"
    echo -e "\nBacking up database to: $backup\n"
    cp $INVOICE_FILE $backup    
}

# confirm invoice number is valid
# input: $1: invoice number
function validateInvNo {
    if [ "$#" -eq 0 ]; then
        echo "No invoice number supplied."
        exit 1
    fi

    local inv_no=$1
    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number: $inv_no"
        exit 1
    fi 

    # limit search to exact matches (ie, 'grep 4' should only return 4, not 14, 24, 40, ...)
    match=$(cat $INVOICE_FILE | sed "1d" | cut -f1 -d, | grep "^"$inv_no"$")
    if [ -z $match ]; then 
        echo "Invoice not found: $inv_no"
        exit 1
    fi
}

# print a single invoice by number, adding a days_past_due column
# input: $1: invoice number
function showInvByNumber {
    if [ "$#" -eq 0 ]; then
        echo "No invoice number supplied."
        exit 1
    fi

    local inv_no=$1
    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number: $inv_no"
        exit 1
    fi 

    cat $INVOICE_FILE | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        awk -F, -v OFS="," -v today="$(date +%s)" 'NR==1 { $(NF+1)="days_past_due"; print $0; } \
            NR>1 { if ($6 < $4 || $6 == "NA") { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; $8=int((today-inv_dt)/86400) } else { $8="--"}; print $0 }' | \
            column -tx -s,

}

function doAdd {
    echo -e "\nAdd invoice"
    echo -e "Invoices database: $INVOICE_FILE\n"
    # next invoice number
    next=$(( $(cat $INVOICE_FILE | sed "1d" | cut -f1 -d, | sort -n | tail -1) + 1 ))
    today=$(date +%Y-%m-%d)

    read -p "Invoice # [$next]: " inv_no
    if [ "$inv_no" == "" ]; then 
        inv_no=$next
    fi

    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number."
        exit 1
    fi 

    match=$(cat $INVOICE_FILE | sed "1d" | cut -f1 -d, | grep $inv_no)
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

        echo "$inv_no,$d,$client,$amt,NA,NA,NA" >> $INVOICE_FILE

        echo "Record added."
    else    
        echo "Record discarded."
    fi
}

function doClients {
    echo -e "\nListing clientIDs"
    echo -e "Invoices database: $INVOICE_FILE\n"

    cat $INVOICE_FILE | sed '1d' | cut -f3 -d, | sort | uniq | column
}

# input: $1 (optional): filename
function doDefault {
    defaultfile=$1
    if [ -z "$defaultfile" ]; then 
        read -p "Filename: " defaultfile
    fi 

    if [ ! -e $INVOICE_DIR/$defaultfile ]; then 
        echo "File not found: $INVOICE_DIR/$defaultfile"
        echo -e "Use \`invoices newfile\` to create new invoice database."
        exit 1
    fi 

    local answer
    if [ -e $CONFIG_FILE ]; then 
        echo -e "\nCurrent default invoices database: $(cat $CONFIG_FILE | grep INVOICE_FILE | cut -f2 -d=)"
        read -p "Make $defaultfile default database instead [n]: " answer 
        if [[ "$answer" == "" ]]; then    
            answer="n"
        fi 

        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            cp $CONFIG_FILE $CONFIG_FILE".bak"
            cat $CONFIG_FILE | sed -E "/INVOICE_FILE/ s/=[a-zA-Z0-9\/\.]+/=$defaultfile/" > tmp && mv tmp $CONFIG_FILE
#            echo "export INVOICE_FILE=$defaultfile" > $CONFIG_FILE
        fi
    else 
        echo "export INVOICE_FILE=$defaultfile" > $CONFIG_FILE 
    fi

}

# input: $1 (optional): invoice number
function doDelete {
    echo -e "\nDelete invoice"
    echo -e "Invoices database: $INVOICE_FILE\n"

    if [ "$#" -eq 0 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    showInvByNumber $inv_no

    local answer
    read -p "Delete this invoice? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        # make a backup of the database...
        backupCSV

        cat $INVOICE_FILE | \
            awk -F, -v i="$inv_no" '{ if (NR==1 || $1 != i) print $0 }' > tmp && mv tmp $INVOICE_FILE

        cat $INVOICE_FILE | column -tx -s,
        echo -e "\nInvoice deleted."
    else
        echo -e "\nDelete operation canceled."
    fi
}

# input: $1 (optional): invoice number
function doEdit {
    echo -e "\nEdit invoice"
    echo -e "Invoices database: $INVOICE_FILE\n"

    if [ "$#" -eq 0 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    showInvByNumber $inv_no

    local answer
    read -p "Edit this invoice? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        inv_dt=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f2 -d,)
        client=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f3 -d,)
        amt_due=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f4 -d,)
        pd_dt=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f5 -d,)
        amt_pd=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f6 -d,)
        taxes=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1==i) print $0 }' | cut -f7 -d,)

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
        cat $INVOICE_FILE | \
            awk -F, -v i="$inv_no" -v s="$s" '{ if ($1 == i) print s; else print $0 }' > tmp && mv tmp $INVOICE_FILE

        echo -e "\n"
        cat $INVOICE_FILE | \
            awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
            column -tx -s,

        echo -e "\nRecord updated."
    else 
        echo -e "\nEdit operation canceled."
    fi
}

function doList {
    echo -e "\nList invoices"
    echo -e "Invoices database: $INVOICE_FILE\n"

    # anything to print?
    if [[ $(cat $INVOICE_FILE | wc -l) -gt 1 ]]; then
        cat $INVOICE_FILE | \
            awk -F, -v OFS="," -v today="$(date +%s)" 'NR==1 { $(NF+1)="days_past_due"; print $0; } \
                NR>1 { if ($6 < $4 || $6 == "NA") { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; $8=int((today-inv_dt)/86400) } else { $8="--" }; print $0 }' | \
                column -tx -s,
    else    
        echo "No invoices to list."
    fi 
}

# input: $1 (optional): filename
function doNewDb {
    echo -e "\nCreate new invoice database"

    newfile=$1
    if [[ -z "$newfile" ]]; then 
        read -p "Filename [$DEFAULT_INVOICE_FILENAME]: " newfile

        if [[ "$newfile" == "" ]]; then   
            newfile=$DEFAULT_INVOICE_FILENAME
        fi
    fi 

    local answer="y"
    if [ -e $INVOICE_DIR/$newfile ]; then
        echo -e "File $INVOICE_DIR/$newfile already exists." 
        read -p "Do you want to overwrite it [n]: " answer
    fi 

    if [[ "$answer" == "" ]]; then  
        answer="n"
    fi

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo $colnames > $INVOICE_DIR/$newfile 
        echo "File $INVOICE_DIR/$newfile created."

        doDefault $newfile 
    else 
        echo "File creation canceled."
    fi 
}

# input: $1 (optional): invoice number
function doPay {
    echo -e "\nPay invoice"
    echo -e "Invoices database: $INVOICE_FILE\n"

    if [ "$#" -eq 0 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    showInvByNumber $inv_no

    pd=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f6 -d,)
    due=$(cat $INVOICE_FILE | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f4 -d,)

    if [[ "$pd" != "NA" && "$pd" -eq "$due" ]]; then
        echo "Invoice already paid."
    
    else 
        local answer
        read -p "Mark this invoice paid? [n]: " answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
            today=$(date +%Y-%m-%d)

            # see https://stackoverflow.com/questions/16529716/save-modifications-in-place-with-awk
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

            cat $INVOICE_FILE | \
                awk -F, -v OFS="," -v i="$inv_no" -v a="$amt" -v d="$d" '{ if ($1==i) { $6=a; $5=d } print $0 }' > tmp && mv tmp $INVOICE_FILE

            showInvByNumber $inv_no

            echo -e "\nInvoice paid.\n"
        else 
            echo -e "\nInvoice unchanged."
        fi
    fi 
}

# input: $1 (optional): clientID
function doReport {
    echo -e "\nInvoice report"
    echo -e "Invoices database: $INVOICE_FILE\n"

    if [ "$#" -eq 0 ]; then
        read -p "ClientID: " client 
    else 
        client=$1
    fi 

    match=$(cat $INVOICE_FILE | sed "1d" | cut -f3 -d, | sort | uniq | grep "$client")
    if [ -z $match ]; then 
        echo "No records found for client: $client."
        exit 1
    fi 

    echo -e "\nClientID:\t$client"
    cat $INVOICE_FILE | \
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
    # cat $INVOICE_FILE | \
    #     awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
    #     awk -F, -v OFS="," 'NR==1 { $(NF+1)="past_due"; print $0 } 
    #                         NR>1 { if ($6 != $4) print $0,$4-$6; else print $0 }' | \
    #     column -tx -s,

        # this version of the code calculates the number of days an invoice is past-due.
    cat $INVOICE_FILE | \
        awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
        awk -F, -v OFS="," -v today="$(date +%s)" 'NR==1 { $(NF+1)="days_past_due"; print $0; } \
                NR>1 { if ($6 < $4 || $6 == "NA") { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; $8=int((today-inv_dt)/86400) } else { $8="--" }; print $0 }' | \
        column -tx -s,
}

# input: $1 (optional): invoice number
function doShow {
    echo -e "\nShow invoice"
    echo -e "Invoices database: $INVOICE_FILE\n"

    if [ "$#" -eq 0 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    showInvByNumber $inv_no
}

function doSummary {
    echo -e "\nClient summary"
    echo -e "Invoices database: $INVOICE_FILE\n"

    # for each client, tally # of invoices, amt billed, amt paid, balance due; write the data out as a CSV
    data=$(cat $INVOICE_FILE | sed "1d" | \
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
    echo -e "\nTaxes"
    echo -e "Invoices database: $INVOICE_FILE\n"

    # check to see if any invoices have been paid but not taxed
    untaxed=$(cat $INVOICE_FILE | awk -F, '{ if ($7 == "NA" && $6 != "NA") print $0 }')
    if [ -z "$untaxed" ]; then
        echo -e "\nAll paid invoices have been taxed."
    else 
        # print the untaxed records
        echo -e "$colnames\n$untaxed" | column -tx -s,

        # tally and print the total amount untaxed
        echo -e "$untaxed" | cut -f6 -d, | awk '{ SUM += $1 } END { print "\nUntaxed income: " SUM }'

        local answer 
        read -p "Mark taxes paid for these invoices? [n]: " answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
            # make a backup of the database...
            backupCSV

            read -p "Value for taxes field: " taxes

            cat $INVOICE_FILE | \
                awk -F, -v OFS="," -v t="$taxes" '{ if ($7=="NA" && $6 != "NA") { $7=t } print $0 }' > tmp && mv tmp $INVOICE_FILE

            doList
            echo -e "\nRecord(s) updated.\n"
        else   
            echo -e "\nRecord(s) unchanged."
        fi
    fi     
}

function doUnpaid {
    echo -e "\nOutstanding invoices:"
    echo -e "Invoices database: $INVOICE_FILE\n"

    # this version of the code shows the outstanding balance
#    cat $INVOICE_FILE | \
#        awk -F, -v OFS="," 'NR==1 { $(NF+1)="bal_due"; print $0 } NR>1 { if ($6 != $4) print $0,$4-$6 }' | \
#        column -tx -s,

    # count unpaid invoices
    unpaid=$(cat $INVOICE_FILE | awk -F, 'NR>1 { if (($6 < $4) || ($6 == "NA")) { print $0 } }' | wc -l )

    if [ $unpaid -gt 0 ]; then 
    # this version of the code calculates the number of days an invoice is past-due.
        cat $INVOICE_FILE | \
            awk -F, -v OFS="," -v today="$(date +%s)" 'NR==1 { $(NF+1)="days_past_due"; print $0; } NR>1 { if (($6 < $4) || ($6 == "NA")) { "date -j -f %Y-%m-%d " $2 " +%s" | getline inv_dt; print $0,int ((today-inv_dt)/86400) } }' | \
            column -tx -s,

        echo -e "\n\tUnpaid summary:"
        cat $INVOICE_FILE | \
            awk -F, '{ a[$3] += $4-$6; DUE+=$4-$6; } END { for (i in a) if (a[i] != 0) print "\t"i": $"a[i]; print "\n\tTotal due: $"DUE,"\n" }'
    else    
        echo "No unpaid invoices found."
    fi    
}

function main {
    local answer

    # $CONFIG_FILE provides the location of the invoices database
    if [ -e $CONFIG_FILE ]; then
        source $CONFIG_FILE
    else 
        echo "~/$CONFIG_FILE file not found."
        echo -e "Be sure to move \`invoices.config\` to your home directory" 
        echo -e "and customize it to your directory structure."
        exit 1
    fi 

    if [[ -z $INVOICE_FILE || -z $INVOICE_DIR ]]; then
        echo -e "Error: INVOICE_FILE and/or INVOICE_DIR not set."
        echo -e "Check your \`~/invoices.config\` file."
        exit 1
    fi 
    INVOICE_FILE=$INVOICE_DIR/$INVOICE_FILE

    # if the last cmdline argument is a csv file, use that as the database instead
    # see https://unix.stackexchange.com/questions/444829/how-does-work-in-bash-to-get-the-last-command-line-argument
    match=$(echo ${!#} | grep "\.csv$")
    if [ $match ]; then
        INVOICE_FILE=$match
        # remove the filename from the arg list
        # see https://stackoverflow.com/questions/37624085/delete-final-positional-argument-from-command-in-bash
        set -- "${@: 1: $#-1}"
    fi

    # if $INVOICE_FILE is not set, no database has been found
    # if [[ -z $INVOICE_FILE || -z $INVOICE_DIR ]]; then
    #     echo -e "Error: No invoices database found." 
    #     echo -e "Create new database with \`invoices newfile\`."
    #     echo -e "Set default database with \`echo \"export INVOICE_FILE=<filename>\" > $CONFIG_FILE\`.\n"
    #     usage 
    #     exit 1
    # fi 

    # if $INVOICE_FILE doesn't exist, exit.
    if [ ! -e $INVOICE_FILE ]; then
        echo -e "\nError: File not found: $INVOICE_FILE\n"
        exit 
    fi

    # there should be at least one argument provided
    if [ "$#" -eq 0 ]; then
        echo -e "Error: Command required.\n"
        usage
        exit 1
    fi 

    command=$1
    shift 

    case $command in
    "add")
        doAdd "$@"
        ;;

    "clients")
        doClients "$@"
        ;;

    "default")
        doDefault $match
        ;;

    "delete")
        doDelete "$@"
        ;;

    "edit")
        doEdit "$@"
        ;;

    "help")
        usage 
        ;;

    "list")
        doList "$@"
        ;;

    "newfile")
        doNewDb $match
        ;; 

    "pay")
        doPay "$@"
        ;;

    "report")
        doReport "$@" 
        ;;

    "show")
        doShow "$@"
        ;;

    "summary")
        doSummary "$@"
        ;;

    "taxes")
        doTaxes "$@"
        ;;

    "unpaid")
        doUnpaid "$@"
        ;;

    *)
        echo "Error: command not recognized"
        usage
        ;;
    esac
}

main "$@"