#!/bin/bash
# Mine cpp dependencies

if ! dpkg -l g++ &> /dev/null
then
	sudo apt install g++
fi

if ! dpkg -l make &> /dev/null
then
	sudo apt install make
fi

if ! dpkg -l openssh-server &> /dev/null
then
	sudo apt install openssh-server
fi

if ! dpkg -l libboost-dev &> /dev/null
then
	sudo apt install libboost-dev
fi

if ! dpkg -l libgnuplot-iostream-dev &> /dev/null
then
	sudo apt install libgnuplot-iostream-dev
fi

if ! dpkg -l clinfo &> /dev/null
then
	apt install -y clinfo
fi
