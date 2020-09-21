#! /bin/bash
# Script to handle freelance invoices
# (c) 2020 Jeffrey M. Perkel
#
# This script creates (if it does not exist) and manipulates a comma-separated values (CSV)-based list of invoices
#


# variables
csvfile=~/mysheet.csv
fields="inv_no,inv_date,customer,amt_billed,paid_date,amt_paid,taxes"

# functions
function usage() {
	echo -e "INVOICES.SH: Script to handle freelance invoices"
    echo -e "USAGE: $0 [COMMAND] <optional-params>"
    echo -e "\tCOMMANDS:"
    echo -e "\t\tadd\tAdd invoice"
    echo -e "\t\tclients\tList clients"
    echo -e "\t\tdelete\tDelete invoice <optional: invoice #>"
    echo -e "\t\tedit\tEdit invoice <optional: invoice #>"
    echo -e "\t\thelp\tDisplay help"
    echo -e "\t\tlist\tList all invoices"
    echo -e "\t\tpay\tPay invoice <optional: invoice #>"
    echo -e "\t\treport\tDisplay summary for one client <optional: client_ID>"
    echo -e "\t\tshow\tDisplay single invoice <optional: invoice #>"
    echo -e "\t\ttaxes\tMark taxes paid"
    echo -e "\t\tunpaid\tList unpaid invoices"

}

# confirm invoice number is valid
# input: $1: an invoice number
function validateInvNo {
    local inv_no=$1
    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number."
        exit 1
    fi 

    match=$(cat ~/mysheet.csv | sed "1d" | cut -f1 -d, | sort -n | grep $inv_no)
    if [ -z $match ]; then 
        echo "Invoice not found: $inv_no."
        exit 1
    fi
}

function doAdd {
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

    match=$(cat ~/mysheet.csv | sed "1d" | cut -f1 -d, | sort -n | grep $inv_no)
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

    read -p "Client: " client 

    while [[ $amt == "" ]]; do 
        read -p "Amount due: " amt 
    done 

    if [[ ! "$amt" =~ ^[0-9.]+$ ]]; then 
        echo "Invalid amount."
        exit 1
    fi 

    data=$(echo "$inv_no,$d,$client,$amt,NA,NA,NA")
    printf "%s \n %s \n" $fields $data | column -tx -s ','

    read -p "Write record to file [y]: " answer 
    if [[ "$answer" == "" ]]; then
        answer="y"
    fi

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        echo "$inv_no,$d,$client,$amt,NA,NA,NA" >> $csvfile
#        cat $csvfile | \
#            awk -F, -v i="$inv_no" '{ if (NR==1 || $1==i) print $0 }' | column -tx -s ','
        echo "Record added."
    else    
        echo "Record discarded."
    fi
}

function doClients {
        echo "Listing clients:"
    cat $csvfile | sed '1d' | cut -f3 -d, | sort | uniq
}

# input: $1 (optional): invoice number
function doDelete {
    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s ','

    local answer
    read -p "Delete this invoice? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        cat $csvfile | \
            awk -F, -v i="$inv_no" '{ if (NR==1 || $1 != i) print $0 }' > tmp && mv tmp $csvfile

        cat $csvfile | column -tx -s ','
        echo "Invoice deleted."
    fi
}

# input: $1 (optional): invoice number
function doEdit {
    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s ','

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
        read -p "Client [$client]: " c
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

        s=$(echo "$inv_no,$inv_dt,$client,$amt_due,$pd_dt,$amt_pd,$taxes")
        cat $csvfile | \
            awk -F, -v i="$inv_no" -v s="$s" '{ if ($1 == i) print s; else print $0 }' > tmp && mv tmp $csvfile

        echo -e "\n"
        cat $csvfile | \
            awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
            column -tx -s ','

        echo -e "\nRecord updated."
    fi
}

function doList {
    cat $csvfile | column -tx -s ','
}

# input: $1 (optional): invoice number
function doPay {
    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s ','

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

            if [[ $amt == "" ]]; then
                amt=$due
            fi 

            if [[ $d == "" ]]; then
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

            cat $csvfile | \
                awk -F, -v OFS="," -v i="$inv_no" -v a="$amt" -v d="$d" '{ if ($1==i) { $6=a; $5=d } print $0 }' > tmp && mv tmp $csvfile
            cat $csvfile | \
                awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
                column -tx -s ','

            echo -e "Invoice paid.\n"

        else 
            echo "Invoice already paid."
        fi
    fi 
}

# input: $1 (optional): clientID
function doReport {
    if [ "$#" -lt 1 ]; then
        read -p "Client: " client 
    else 
        client=$1
    fi 

    match=$(cat ~/mysheet.csv | sed "1d" | cut -f3 -d, | sort | uniq | grep $client)
    if [ -z $match ]; then 
        echo "No records found for client: $client."
        exit 1
    fi 

    echo -e "\nClient: $client"
    cat $csvfile | \
        awk -F, -v client="$client" '$3==client { COUNT++; BILLED += $4; PAID += $6; DUE += $4-$6 } END \
            { if (COUNT == 0) print "No invoices found.\n" 
            else print "No. invoices:\t",COUNT, \
                "\nTotal billed:\t",BILLED,
                "\nTotal paid:\t",PAID,
                "\nAmount due:\t",DUE,
                "\n" 
            }'
    echo "Invoices:"
    cat $csvfile | \
        awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
        awk -F, -v OFS="," 'NR==1 { $8="past_due"; print $0 } 
                            NR>1 { if ($6 != $4) print $0,$4-$6; else print $0 }' | \
        column -tx -s ','
}

# input: $1 (optional): invoice number
function doShow {
    if [ "$#" -lt 1 ]; then
        read -p "Invoice # : " inv_no 
    else 
        inv_no=$1
    fi 

    validateInvNo $inv_no

    cat $csvfile | \
        awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
        column -tx -s ','
}

function doTaxes {
    cat $csvfile | \
        awk -F, '{ if (($7 == "NA" && $6 != "NA") || NR==1) print $0 }' | \
        column -tx -s ','

    taxable=$(cat $csvfile | awk -F, '$7 == "NA" && $6 != "NA" { INC += $6; } END { print "Untaxed income: " INC }')
    echo -e "\n$taxable"

    local answer 
    read -p "Mark taxes paid for these invoices? [n]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then 
        read -p "Value for taxes field: " taxes

        cat $csvfile | \
            awk -F, -v OFS="," -v t="$taxes" '{ if ($7=="NA") { $7=t } print $0 }' > tmp && mv tmp $csvfile
        cat $csvfile | column -tx -s ','
        echo -e "Record updated.\n"
    fi     
}

function doUnpaid {
    echo "Outstanding invoices:"
    cat $csvfile | \
        awk -F, -v OFS="," 'NR==1 { $8="bal_due"; print $0 } NR>1 { if ($6 != $4) print $0,$4-$6 }' | \
        column -tx -s ','

    echo -e "\n\tUnpaid summary:"
    cat $csvfile | \
        awk -F, '{ a[$3] += $4-$6; DUE+=$4-$6; } END { for (i in a) if (a[i] != 0) print "\t"i": $"a[i]; print "\n\tTotal due: $"DUE,"\n" }'
}

function main {
    if [ ! -e $csvfile ]; then 
        local answer 
        read -p "Invoice database not found. Would you like to create one? [y]: " answer 
        if [[ "$answer" == "" ]]; then 
            answer="y"
        fi

        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            echo $fields > $csvfile 
            echo "File $csvfile created."

        else 
            echo "No invoice database found."
            exit 1
        fi 
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

    "pay")
        doPay $1
        ;;

    "report")
        doReport $1 
        ;;

    "show")
        doShow $1
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

main $1 $2