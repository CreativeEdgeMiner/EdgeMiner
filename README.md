# EdgeMiner
Altcoin Mining and Rig Management Software

EDGEMINER CONTROL README

All controls for Edgeminer are to be initiated with the command


./edgeminer (command arguments here)

you may need to use root access on certain commands, that can be done by adding the word: sudo 
at the beginning of the command.



Software that is currently supported:
	-ethdcrminer64 (Claymore)
	-optiminer-equihash (Optiminer)
	-lolMiner-mnx (lolMiner)

Currently supported coins:
	Minexcoin
	ZCash
	Bitcoin Gold
	HUSH
	Zero
	Komodo
	Bitcoin Z
	Ethereum
	Ethereum Classic
	Siacoin
	Library
	Decred
	Pascal

Corresponding coin command line usage
	-c minex
	-c zcash
	-c bitgold
	-c hush
	-c zero
	-c komodo
	-c bitcoinz
	-c eth
	-c etc
	-c exp
	-c sia
	-c lbc
	-c dcr
	-c pasc
It is important to specialize each coin name with -c before using the abbreviation. Any other flags correspond to different variables such as the address. They will be listed with their proper flags in this README, if you need to check them, running "sudo ./edgeminer -h" will give a list of commands with more brevity.  

IMPORTANT:
Currently, the supported GPU's are Rx 4XX/5XX series cards, as well as Nvidia 10XX/9XX series cards. 


More accessibility for graphics cards are being added as this software continues to develop.


Example Command Line Usage:

IMPORTANT: BEFORE THE MINER MAY BE USED ENSURE THAT PROPER OPENCL DRIVERS ARE INSTALLED:

Replace address, name and pool in command with custom pool and address
This command must be run to configure the mining software:

 ./edgeminer -s ethdcrminer64 -c eth -p 
(poolname:portnumber) --add-pool --set-default-pool 
--set-addr (wallet-address) --set-name (setnameatpool) 
--switch

Basic Edgeminer Commands after install and configuration:


(most require root access)
sudo ./edgeminer --start (run mining software and track GPU statistics
)
./edgeminer --pause (pause mining software)

./edgeminer --stop (stop Edgeminer and update)

./edgeminer --resume (resume paused miner)

./edgeminer --restart (update and restart miner)

./edgeminer --reboot (close software, update, and reboot computer)

./edgeminer --shutdown (close software, update, and shutdown computer)

sudo ./edgeminer --start --no-overclock	(disable fan control and overclocks) 


Information Commands

./edgeminer --list (gives current miner configuration)

./edgeminer --list-coins (print what coins are currently available to mine)

./edgeminer --list-software (print different mining software)

./edgeminer --list-pools (print configured pools)

./edgeminer --list-addr (print configured wallet addresses)

./edgeminer --list-stats (print gpu type/clock, may also give specific edition of card)

./edgeminer --list-drivers (prints drivers that are preconfigured)

./edgeminer --list-oc	(displays overclock values)

./edgeminer --list-oc-limits (displays maximum recommended OC)



To set fan speed

sudo ./edgeminer --gpu (comma, seperated, list, of each gpu number) --fan-speed (comma, seperated, list, of fan percentage with no %)

for example:

sudo ./edgeminer --gpu 0,1,4 --fan-speed 80,85,77









