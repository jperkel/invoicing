# Bash-based invoicing system

This script creates and manages a comma-separated values (CSV)-based invoice spreadsheet. The sheet includes 7 columns: 
- Invoice #
- Invoice date
- CustomerID (no spaces, eg CLIENT_A or CUSTOMER_1)
- Amount billed
- Date paid 
- Amount paid 
- Taxes (eg: "PAID", or "Q2/20" or whatever you find useful)

By default the spreadsheet is located in `~/mysheet.csv`, but you can modify that on line 10. 

The script supports the following commands: 
- `add`: Add invoice
- `clients`: List clients
- `delete`: Delete invoice <invoice #>
- `edit`: Edit invoice <invoice #>
- `help`: Display help
- `list`: List all invoices
- `pay`: Pay invoice <invoice #>
- `report`: Show details for one client <client ID>
- `show`: Display single invoice <invoice #>
- `taxes`: Mark taxes paid
- `unpaid`: List unpaid invoices

Invoke those commands by entering them after the script name in a command line terminal: `invoices [COMMAND] <optional-parameters>`. For example, `$ invoices edit 10` allows you to edit invoice 10. `$ invoices report CLIENT_A` summarizes your invoices from the client whose clientID is CLIENT_A. In these two examples, the invoice number and name of the client are optional; if you omit them, the script will prompt you instead -- only the command itself is required.)

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
