# Bash-based invoicing system

This script creates and manages a comma-separated values (CSV)-based invoice spreadsheet. The sheet includes 7 columns: 
- Invoice #
- Invoice date
- CustomerID (no spaces, eg CLIENT_A or CUSTOMER_1)
- Amount billed
- Date paid 
- Amount paid 
- Taxes (eg: "PAID", or "Q2/20" or whatever you find useful)

By default the spreadsheet is located in `~/mysheet.csv`, but you can modify that on line 10. An example spreadsheet is included in the repository. 

The script supports the following commands: 
- `add`: Add invoice
- `clients`: List clients
- `delete`: Delete invoice <invoice #>
- `edit`: Edit invoice <invoice #>
- `help`: Display help
- `list`: List all invoices
- `pay`: Pay invoice <invoice #>
- `report`: Show details for one client <client ID>
- `show`: Show single invoice <invoice #>
- `summary`: Show summary of all clients
- `taxes`: Mark taxes paid
- `unpaid`: List unpaid invoices

Invoke those commands by entering them after the script name in a command line terminal: `invoices [COMMAND] <optional-parameters>`. For example, `$ invoices edit 10` allows you to edit invoice 10. `$ invoices report CLIENT_A` summarizes your invoices from the client whose clientID is CLIENT_A. In these two examples, the invoice number and name of the client are optional; if you omit them, the script will prompt you instead -- only the command itself is required.)

Here is the result of `invoices unpaid` on the example database included in this repo: 

```
$ invoices unpaid
Outstanding invoices:
inv_no  inv_date    customer  amt_billed  paid_date  amt_paid  taxes_pd  bal_due
43      2015-04-01  CLIENT_C  1200        NA         NA        NA        1200
46      2020-09-20  CLIENT_N  1000        NA         NA        NA        1000
47      2020-09-20  CLIENT_O  900         NA         NA        NA        900
48      2020-09-20  CLIENT_P  1200        NA         NA        NA        1200
49      2020-09-20  CLIENT_P  2700        NA         NA        NA        2700
50      2020-09-20  CLIENT_M  250         NA         NA        NA        250
51      2020-09-20  CLIENT_P  500         NA         NA        NA        500

	Unpaid summary:
	CLIENT_C: $1200
	CLIENT_M: $250
	CLIENT_N: $1000
	CLIENT_O: $900
	CLIENT_P: $4400

	Total due: $7750
```

And this is the result of `invoices report CLIENT_M`: 

```
$ invoices report CLIENT_M

Client:		CLIENT_M
No. invoices:	4
Total billed:	3450
Total paid:	3200
Amount due:	250

Invoices:
inv_no  inv_date    customer  amt_billed  paid_date   amt_paid  taxes_pd  past_due
35      2008-11-15  CLIENT_M  600         2009-03-01  600       Q2/09
38      2009-01-20  CLIENT_M  600         2009-03-15  600       Q2/09
45      2020-09-19  CLIENT_M  2000        2020-09-20  2000      NA
50      2020-09-20  CLIENT_M  250         NA          NA        NA        250
```

# Installation
Install the script (`invoices.sh`) somewhere in your home directory. From a command line terminal (eg Mac Terminal) you should be able to execute it with `path/to/invoices.sh [COMMAND]`. For simplicity, add an alias to your bash configuration file, eg: `alias invoices=~/Scripts/invoices.sh`. Once you reload your configuration file (e.g., `source .bash_profile`), you will be able to invoke the script directly, eg: `invoices clients`.

# License
(from https://opensource.org/licenses/BSD-3-Clause) 
Copyright 2020 Jeffrey M. Perkel

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
