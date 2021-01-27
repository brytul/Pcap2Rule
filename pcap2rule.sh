#!/bin/bash
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

#check dependencies exist for Zeek
sudo apt-get -y install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev


# check if zeek installed
if which zeek; then
    echo Zeek installed
else
    echo -e ${RED}Installing Zeek...${NC}
    #echo -e ${PURPLE}Zeek missing - https://docs.zeek.org/en/current/install/install.html${NC}
    #exit 1
    sudo apt-get -y install git cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev python3-dev python3-pip python3-tk python3-lxml python3-six
    git clone --recursive https://github.com/zeek/zeek
    cd zeek/
    ./configure 
    sudo make
    sudo make install
    sudo ln --symbolic /usr/local/zeek/bin/zeek /usr/bin/zeek
    echo "export PATH=$PATH:/usr/local/zeek/bin" >> .bashrc #for next startup
    echo -e ${RED}Zeek installed...${NC}
fi

if [ $# -ne 3 ]; then
    #echo Improper args
    echo -e ${PURPLE}Please enter the following args: [pcapng] [zeek profile] [rules name]${NC}
    exit 1
else
    #Validate file existance
    echo Chosen pcapng: $1    
    if [ ! -f "$1" ]; then
        echo -e ${PURPLE}$1 .pcapng does not exist${NC}
        exit 1
    fi
    echo Chosen zeek profile: $2
    if [ ! -f "$2" ]; then
        echo -e ${PURPLE}$2 .zeek profile does not exist${NC}
        exit 1
    fi

    #identifies the type of .zeek profile we are working with based on name (ex. printer_http.zeek)
    if [[ "$2" =~ .*"http"* ]]; then
        RADIO_OUTPUT='radio_http_msgs.log'
        PORT=80
    fi
    
    echo Chosen rules name: $3
    if [ -f "$3" ]; then
        echo -e ${PURPLE}$3 Choose a nonexistant filename${NC}
        exit 1
    fi
fi

#Checks that $RADIO_OUTPUT and $PORT have been set based on the .zeek profile 
if [ -z $RADIO_OUTPUT ] | [ -z $PORT ]; then 
    echo -e ${PURPLE}"We could not identify the zeek profile properly"${NC}
    exit 1
fi

echo

#Begin zeek -> log files
zeek -Cr $1 $2 
if [ $? -eq 0 ]; then
    echo -e ${RED}Zeek finished...${NC}
    if [ -f $RADIO_OUTPUT ]; then
        echo $RADIO_OUTPUT created succesfully
    else
        echo Missing important log file
    fi
else    
    echo Zeek failed - refer to error above.
fi
#End zeek -> log files

#Begin Bro2Model -> model/proto
if [ -f Bro2Model.java ]; then
    sudo apt install openjdk-11-jdk-headless
    javac Bro2Model.java && echo Compiled Bro2Model || echo Failure to compile Bro2Model exit
    java Bro2Model radio_http_msgs.log && echo -e ${RED}Finished Bro2Model...${NC} || echo Failed Bro2Model exit
    echo
    if [ -f "proto.txt" -a -f "model.txt" ]; then
        echo Proto and model created
    else
        echo Cannot find proto/model files after running Bro2Model
    fi
else
    echo Missing Bro2Model.java
    exit 1
fi
#End Bro2Model -> model/proto

#Check if python3 installed
python3 --version && echo Python3 installed || echo Please install Python3 before running newModel2Rule.py exit

#Begin newModel2Rule -> snort.rules
if [ -f newModel2Rule.py ]; then
    python3 newModel2Rule.py -M model.txt -P proto.txt -s $PORT -n ${1%.*} -R $3.rules && echo -e ${RED}DONE...${NC} || echo Failed to run newModel2Rule.py    
else
    echo Missing newModel2Rule.py
    exit 1
fi