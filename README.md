# Bash-based invoicing system

This script creates and manages a comma-separated values (CSV)-based invoice spreadsheet. The sheet includes 7 columns: 
- Invoice #
- Invoice date
- ClientID (no spaces, eg CLIENT_A or CUSTOMER_1)
- Amount billed
- Date paid 
- Amount paid 
- Taxes (eg: "PAID", or "Q2/20" or whatever you find useful)

By default the spreadsheet is located in `~/myinvoices.csv`, but you can modify that on line 10. An example spreadsheet is included in the repository. Alternatively, supply the spreadsheet location as the last command-line argument. For instance: `invoices report CLIENT_A mysheet2.csv`.

The script supports the following commands: 
- `add`: Add invoice
- `clients`: List clientIDs
- `default`: Set default invoice database <optional: filename>
- `delete`: Delete invoice <optional: invoice #>
- `edit`: Edit invoice <optional: invoice #>
- `help`: Display help
- `list`: List all invoices
- `newfile`: Create new invoices database <optional: filename>
- `pay`: Pay invoice <optional: invoice #>
- `report`: Show details for one client <optional: clientID>
- `show`: Show single invoice <optional: invoice #>
- `summary`: Show summary of all clients
- `taxes`: Mark taxes paid
- `unpaid`: List unpaid invoices

Invoke those commands by entering them after the script name in a command line terminal: `invoices [COMMAND] <optional-parameters>`. For example, `$ invoices edit 10` allows you to edit invoice 10. `$ invoices report CLIENT_A` summarizes your invoices from the client whose clientID is CLIENT_A. In these two examples, the invoice number and name of the client are optional; if you omit them, the script will prompt you instead -- only the command itself is required.)

Here is the result of `invoices unpaid` on the example database included in this repo: 

```
$ invoices unpaid
Outstanding invoices:
inv_no  inv_date    clientID  amt_billed  paid_date  amt_paid  taxes_pd  days_past_due
43      2017-04-01  CLIENT_C  1200        NA         NA        NA        1269
46      2020-09-20  CLIENT_N  1000        NA         NA        NA        1
47      2020-09-20  CLIENT_O  900         NA         NA        NA        1
48      2020-09-20  CLIENT_P  1200        NA         NA        NA        1
49      2020-09-20  CLIENT_P  2700        NA         NA        NA        1
50      2020-09-20  CLIENT_M  250         NA         NA        NA        1
51      2020-09-20  CLIENT_P  500         NA         NA        NA        1
52      2020-09-21  CLIENT_O  300         NA         NA        NA        0

	Unpaid summary:
	CLIENT_C: $1200
	CLIENT_M: $250
	CLIENT_N: $1000
	CLIENT_O: $1200
	CLIENT_P: $4400

	Total due: $8050
```

And this is the result of `invoices report CLIENT_M`: 

```
$ invoices report CLIENT_M

ClientID:		CLIENT_M
No. invoices:	4
Total billed:	3450
Total paid:	3200
Amount due:	250

Invoices:
inv_no  inv_date    clientID  amt_billed  paid_date   amt_paid  taxes_pd  past_due
35      2008-11-15  CLIENT_M  600         2009-03-01  600       Q2/09
38      2009-01-20  CLIENT_M  600         2009-03-15  600       Q2/09
45      2020-09-19  CLIENT_M  2000        2020-09-20  2000      NA
50      2020-09-20  CLIENT_M  250         NA          NA        NA        250
```

# Installation
1. Install the script (`invoices.sh`) somewhere in your home directory. 
2. Make the script executable with `chmod +x invoices.sh`.
3. From a command line terminal (eg Mac Terminal), tell `invoices.sh` where your database is by creating a configuration file `~/invoices.config` and using it to set the `csvfile` environmental variable. For instance, to use the database included in this repo, use `echo "export csvfile=~/myinvoices.csv" > ~/invoices.config`.  
4. You should be able to execute the script with `path/to/invoices.sh [COMMAND]`. For simplicity, add an alias to your bash configuration file, eg: `alias invoices=~/Scripts/invoices.sh`. Once you reload your configuration file (e.g., `source .bash_profile`), you will be able to invoke the script directly, eg: `invoices clients`.  
5. Create a new invoices database with `invoices newfile`.  

# License
(from https://opensource.org/licenses/BSD-3-Clause) 
Copyright 2020 Jeffrey M. Perkel

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
