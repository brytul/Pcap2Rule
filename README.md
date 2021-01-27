# Pcap2Rule
This converts .pcapng files into usable snort rules.

**Pipeline**: Pcapng -> Zeek -> log files -> Bro2Model.java -> proto/model.txt -> newModel2Rule.py -> snort.rules

**Zeek**: Using the provided Pcap, we generate the log files using the .zeek profile

**Bro2Model.java**: The output of zeek is used to create a FSM of the interaction between device and gateway

**newModel2Rule.py**: The proto.txt and model.txt are used to generate the Snort rules

## Usage

This currently only supports http as there is only an http .zeek profile

```sh
./pcap2rule.sh <.pcapng> <.zeek profile> <Name of Snort rules>
```