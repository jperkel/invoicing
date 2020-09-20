# Bash-based Invoicing system

This script creates and manages a comma-separated values (CSV)-based invoice spreadsheet. The sheet includes 7 columns: 
- Invoice #
- Invoice date
- CustomerID
- Amount billed
- Date paid 
- Amount paid 
- Taxes (eg: "PAID", or "Q2/20" or whatever you find useful)

The file is located in `~/mysheet.csv`, but you can modify that on line 10. 

The script supports the following commands: 
- `add`: Add invoice
- `all`: List invoices
- `clients`: List clients
- `delete`: Delete invoice <invoice #>
- `due`: List unpaid invoices
- `edit`: Edit invoice <invoice #>
- `help`: Display help
- `pay`: Pay invoice <invoice #>
- `report`: Show details for one client <client ID>
- `taxes`: Mark taxes paid

To use this script, install it in your home directory. You should be able to execute it with `./invoices.sh [COMMAND]`. For simplicity, add an alias to your bash configuration file, eg: `alias invoices=~/Scripts/invoices.sh`. Once you reload your configuration file (e.g., `source .bash_profile`), you should be able to invoke the script directly, eg: `invoices clients`.
