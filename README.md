# Regtest Launchpad

Launch automated swarms of Bitcoin and Lightning nodes, each with an interactive shell and full suite of development tools. Prototype and deploy your next project with lightning speed!

## How to Use

> *Note: Make sure that docker is installed, and your user is part of the docker group.*

To spin up a basic network of three nodes:

```shell
## Clone this repository, and make it your working directory.
git clone "https://github.com/cmdruid/regtest-node.git"
cd regtest-node

## Compiles all the binaries that we will need. May take a while!
./regnode.sh compile

## Your first (and main) node. Seeds the blockchain and mines blocks.
./regnode.sh --mine master

## Meet Alice, who connects to master and requests funding.
./regnode.sh --faucet master --peers master alice

## Meet Bob, also funded by master, who peers and opens a channel with Alice (using short-hand).
./regnode.sh -f master -p alice -c alice bob

## ... repeat for as many nodes as you like!

## A quick tutorial is also built into the help screen.
./regnode.sh --help
```
Based on the above configuration, each node will automatically connect to their designated peers, request funds from a faucet, and open payment channels. The final argument designates each node with a name tag.

Use the `--mine` flag with your first node in order to initiate the chain. Your miner will detect a new chain, then auto-generate blocks up to a certain height. Block rewards require at least 100 blocks to mature, so the default height is 150.

By default, Your miner is configured to watch the mempool, then auto-generate blocks when it sees an unconfirmed transaction. The default poll time is 2 seconds so that transactionswill confirm quickly. If you wish to deploy multiple miners, you should use longer timings in order to avoid chain splits.

The format for configuring your mining node is `--mine=poll-time,interval-time,fuzz-amount` in seconds. For example, the configuration `0,10,20` will disable polling, schedule a block every 10 seconds, plus a random value between 1 and 20.

The `--peers` and `--channels` flags will intsruct nodes on whom to peer and open channels with. These flags accept a comma-separated list of nametags (*e.x alice,bob,carol*). The `--faucet` flag will instruct your node to request funding from another node. Nodes are smart enough to configure their own wallets, negotiate funding, and ~~balance their channels accordingly~~! *coming soon!*

> Tip: *Use your initial miner node as your main faucet, since the block rewards will have made him filthy rich! Miners may also generate more blocks in order to procure funds if their wallet balance is low.*

Nodes with the `--tor` flag will auto-magically use onion routing when peered with other tor-enabled nodes, no extra configuration required. This flag will also make the endpoints on a given node available as (v3) hidden services. Tor nodes can still communicate with non-tor nodes, but will default to using tor when available.

All the pertinent settings, keys and credentials for running nodes are namespaced and stored in the `/share` folder. Each node will mount and scan this folder in order to peer and communicate with other nodes. Files are refreshed when you restart a given node, so feel free to muck with the settings on a frequent basis!

> Note: *Nodes are designed to work completely over tor, using the `/share` folder. You can copy / distribute a node's shared files onto other machines and build a regtest network across the web!*

Each node launches with a simple web-wallet for managing invoices and test payments (*provided by sparko*). Nodes will print their local address and login credentials to the console upon startup. You can also manage payments easily using `bitcoin-cli` and `lightning-cli`.

 If you have a node suffering from issues, try running the `entrypoint` command. It is the main startup script for each node, and is designed to be re-run as many times as needed. The script output is designed to be very informative, and will help refresh configurations, restart services, or diagnose / resolve issues that crop up during the startup process.

> Tip: *Use the `--devmode` flag to enter a node's console before the startup script is run. This flag will also mount the /run folder directly, allowing you to hack / modify the source code for this project in real-time. Don't forget to use version control. ;-)*

All nodes ship with Flask and Nodejs included, plus a core library of development tools. Check out the example projects located in `contrib/examples` if you want to jump into web/app development right away!

## Repository Overview

### \#\# ./build

This path contains the build script, related dockerfiles, and compiled binaries. When you run the `start.sh` script, it will fist scan the `build/dockerfiles` and `build/out` path in order to compare files. If a binary appears to be missing, the start script will then call the build script (with the related dockerfile), and request to build the missing binary from source. Compiled binaries are then copied `build/out`.

If you have just cloned this repositry, it's best to run `./regnode.sh compile` as a first step, so that launching your first node doesn't force you to compile everything at once.

All files located in `build/out` are copied over to the main docker image and installed at build time, so feel free to include any binaries you wish! The script recognizes tar.gz compression, and will strip the first folder before unpacking into `/usr`, so make sure to pack your binaries accordingly.

You can also add your own `build/dockerfiles`, or modify the existing ones in order to try different builds and versions. If you add a custom dockerfile, make sure it also names the binary with a matching substring, so the start script can correctly determine if your binary is present / missing.

### \#\# ./config

These are the configuration files used by the main services in the stack. The entire config folder is copied at build time, located at `/root/config` in the image. Feel free to modify these files or add your own, then use `--build` or `--rebuild` to refresh the image when starting a container.

The `.bash_aliases` file is also loaded upon startup, feel free to use it to customize your environment!

### \#\# ./contrib

*Work in progress. Will contain example templates and demos for building bitcoin / lightining connected apps.*

### \#\# ./doc

Documentation will be stored in this folder. More documentation coming soon!

### \#\# ./run

This folder contains the main `entrypoint` script, libraries and tools, plus all other scripts used to manage services in the stack. 

- Most of the source code for this project is located in `lib`.
- Scripts placed in `lib\bin` are available from the container's PATH.
- Projects placed in `plugins` are loaded by lightningd at startup (*folder name must match main script*).
- Scripts placed in `startup` are executed in alpha-numeric order when `entrypoint` is run.

The entire run folder is copied at build time, located at `/root/run` in the image. Feel free to modify these files or add your own, then use `--build` or `--rebuild` to refresh the image when starting a container. When starting a container in `--devmode`, this folder is mounted directly, with files modified in real-time.

### \#\# ./share

Each node will mount this folder on startup, then use it as a shared repository for providing their own configuration data. Each folder is namespaced after a node's hostname, and used by other nodes in order to peer and connect with each other. These files are constantly created and destroyed by their respective nodes, so that the data remains fresh and accurate.

If tor is enabled for a given node, its share data can also be copied to other machines for more complex configurations.

## Development

*Work in progress. Feel free to hack the project on your own!*

There are two main modes to choose from when launching a container: **safe mode** and **development mode**. 

By default, a node will launch in safe mode. A copy of the `/run` folder is made at build time, and code changes to `/run` will not affect the node (unless you rebuild and re-launch). The node will continue to run in the background once you exit the node terminal. The node is also configured to self-restart in the event of a crash.

When launching a node with `--devmode` enabled, a few things change. The `entrypoint` script will not start automatically; you will have to call it yourself. The `/run` folder will be mounted directly into the container, so you can modify the source code in real-time.

Any changes to the source code will apply to *all* nodes. Re-run the start script to apply changes. When you exit the terminal, the container will be instantly destroyed, however the internal `/data` store will persist.

If you end up borking a node, use the `--wipe` flag at launch to erase the node's persistent storage. The start scripts are designed to be robust, and nodes are highly disposable. Feel free to crash, wipe, and re-launch nodes as often as you like!

To mount a folder into your node environment, use the format `--mount local/path:/mount/path`. Paths can be relative or absolute.

To open and forward ports from your node environment, use the format `--ports src1:dest1,src2:dest2, ...`, using a comma to separate port declarations, and colon to separate source:dest ports.

## Contribution

All suggestions and contributions are welcome! If you have any questions about this project, feel free to submit an issue up above, or contact me on social media.

## Tools

**LNURL Decoder**  
https://lnurl.fiatjaf.com/codec

## Resources

**Bitcoin Developer Reference**  
A great resource for documentation on Bitcoin's RPC interface, and other technical details.  
https://developer.bitcoin.org/reference/index.html

**Bitcoin Github Docs**  
Another great resource for all things related to Bitcoin Core.  
https://github.com/bitcoin/bitcoin/tree/master/doc

**Core Lightning Documentation**  
The go-to resource for Core Lightning's RPC interface.  
https://lightning.readthedocs.io

**Core Lighting REST API Docs**  
Documentation for the REST interface that is provided by the RTL team.  
https://github.com/Ride-The-Lightning/c-lightning-REST#apis

**Bolt 12 Landing Page**  
A nice landing page for info regarding the Bolt 12 specification.  
https://bolt12.org

**Sparko Client**  
Incredibly useful web-rpc interface and web-client for Core Lightning.  
https://github.com/fiatjaf/sparko-client

**Pyln-client**  
The main library for interfacing with Core Lightning over RPC. Very powerful.  
https://github.com/ElementsProject/lightning/tree/master/contrib/pyln-client

**Python Documentation**  
Official resource for the python language.  
https://docs.python.org/3

**Flask Documentation**  
The go-to resource for documentation on using Flask.  
https://flask.palletsprojects.com/en/2.1.x

**Node.js Documentation**  
The go-to resource for documentation on using Nodejs.  
https://nodejs.org/api
