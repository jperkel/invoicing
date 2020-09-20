#! /bin/bash

# Script to handle freelance invoices

# variables
csvfile=~/mysheet.csv

usage() {
	echo -e "\n$0: Script to handle freelance invoices"
    echo -e "USAGE: $0 [COMMAND] <params>"
    echo -e "\tCOMMANDS: add, delete, due, edit, list, pay, report <client ID>"
}

case $1 in
"add")
    next=$(( $(cat $csvfile | sed "1d" | cut -f1 -d, | sort -n | tail -1) + 1 ))
    today=$(date +%Y-%m-%d)

    read -p "Invoice # [$next]: " inv_no
    read -p "Date [$today]: " d 
    read -p "Client: " client 

    while [[ $amt == "" ]]; do 
        read -p "Amount due: " amt 
    done 

    if [ "$inv_no" == "" ]; then 
        inv_no=$next
    fi

    if [ "$d" == "" ]; then 
        d=$today
    fi

    if [[ ! "$inv_no" =~ ^[0-9]+$ ]]; then 
        echo "Invalid invoice number."
        exit 1
    fi 

    if [[ ! "$amt" =~ ^[0-9.]+$ ]]; then 
        echo "Invalid amount."
        exit 1
    fi 

    if [[ ! "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then 
        echo "Invalid date."
        exit 1
    fi

    echo "Inv no: $inv_no"
    echo "Date: $d"
    echo "Amt: $amt"

    echo "$inv_no,$d,$client,$amt,NA,NA,NA,NA" >> $csvfile
    cat $csvfile | column -tx -s ','
    ;;

"delete")
    # echo "delete command not implemented"
    ;;

"due")
    echo "Outstanding invoices:"
    cat $csvfile | \
        cut -f1,2,3,4,5,6,8 -d, | \
        awk -F, -v OFS="," 'NR==1 { $8="past_due"; print $0 } NR>1 { if ($6 != $4) print $0,$4-$6 }' | \
        column -tx -s ','

    echo -e "\n\tSummary:"
    cat $csvfile | \
        awk -F, '{ a[$3] += $4-$6; DUE+=$4-$6 } END { for (i in a) if (a[i] != 0) print "\t"i": $"a[i]; print "\n\tTotal due: $"DUE,"\n" }'

    ;;

"edit")
    echo "edit command not implemented"
    ;;

"list")
    echo "Listing clients:"
    cat $csvfile | sed '1d' | cut -f3 -d, | sort | uniq
    ;;

"pay")
    # echo "pay command not implemented"
    read -p "Invoice #: " inv_no
    read -p "Amount paid: " amt 
    read -p "Date: " d 

    pd=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f6 -d,)
    billed=$(cat $csvfile | awk -F, -v i="$inv_no" '{ if ($1 == i) print $0 }' | cut -f4 -d,)
    # echo $pd

    # see https://stackoverflow.com/questions/16529716/save-modifications-in-place-with-awk
    if [[ "$pd" == "NA" || "$pd" -ne "$billed" ]]; then 
        echo -e "Marking invoice paid.\n"
        cat $csvfile | \
            awk -F, -v OFS="," -v i="$inv_no" -v a="$amt" -v d="$d" '{ if ($1==i) { $6=a; $5=d } print $0 }' > tmp && mv tmp $csvfile
        cat $csvfile | \
            awk -F, -v i="$inv_no" '{ if ($1==i || NR==1) print $0 }' | \
            column -tx -s ','

    else 
        echo "Invoice already paid."
    fi 

    # cp $csvfile $csvfile".bak" 
#    cat $csvfile | \
#        awk -F, -v OFS="," -v i="$inv_no" -v a="$amt" -v d="$d" '{ if ($1 == i) $6=a; $5=d; print $0 }' # > $csvfile 
    
#    cat $csvfile | column -tx -s ','
    ;;

"report")
    if [ "$#" -ne 2 ]; then
        read -p "Client: " client 
    else 
        client=$2
    fi 

    echo -e "\nClient: $client"
    cat $csvfile | \
        awk -F, -v client="$client" '$3==client { COUNT++; BILLED += $4; PAID += $6; DUE += $4-$6 } END \
            { if (COUNT == 0) print "No invoices found.\n" 
            else print "No. invoices:\t",COUNT, \
                "\nTotal billed:\t",BILLED,
                "\nTotal paid:\t",PAID,
                "\nTotal due:\t",DUE,
                "\n" 
            }'
    echo "Invoices:"
    cat $csvfile | \
        cut -f1,2,3,4,5,6,8 -d, | \
        # awk -F, -v OFS="," '{
        #     #split($2,a,"-");
        #     #split($5,b,"-");
        #     inv_dt = mktime(sprintf("%d %d %d 0 0 0 0", a[3],a[2],a[1]));
        #     pd_dt = mktime(sprintf("%d %d %d 0 0 0 0", b[3],b[2],b[1]));
        #     $9 = (inv_dt - pd_dt)/86400;
        #     print $0
        #  }' | \
        awk -F, -v client="$client" '{ if (NR==1 || client==$3) print $0 }' | \
        awk -F, -v OFS="," 'NR==1 { $9="past_due"; print $0 } 
                            NR>1 { if ($6 != $4) print $0,$4-$6; else print $0 }' | \
        column -tx -s ','
    ;;

*)
    echo "Error: command not recognized"
    usage
    ;;
esac

#if [[ -n "$1" && -n "$2" ]]; then # if both $1 and $2 exist...
#	grep -E "^["$1"]+$" /usr/share/dict/words | \
#		grep ["$2"] | \
#		awk '{ print length(), $0 }' | \
#		sort -rn |  \
#		awk '{ if (length($0) > 5) { print } }'

#else
#	usage
#fi

