if ! sudo apt-get update
	exit 1
fi

if ! sudo apt-get upgrade
	exit 1
fi

# OhGodATool Download #
if [[ ! -d ./OhGodATool ]]
then
	if ! git clone https://github.com/OhGodACompany/OhGodATool.git
	then
		exit 1
	fi
	cd OhGodATool
	if ! make
	then
		exit 1
	fi
	cd ..
else
	cd OhGodATool
	git pull | tee -a ../"$MINE_LOG"
	cd ..
fi

# Mine cpp dependencies

if ! dpkg -l libboost-all-dev &> /dev/null
then
	if ! sudo apt install libboost-all-dev
	then
		exit 1
	fi
fi

if ! dpkg -l libgnuplot-iostream-dev &> /dev/null
then
	if ! sudo apt install libgnuplot-iostream-dev
	then
		exit 1
	fi
fi

if ! dpkg -l clinfo &> /dev/null
then
	if ! apt install -y clinfo
	then
		exit 1
	fi
fi
 
 # Success
exit 0