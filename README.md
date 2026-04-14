# WLAN Network Modeling Workshop 

## Description:

The WLAN Network Modeling Workshop offers participants a practical, hands-on introduction to end-to-end WLAN network modeling using MATLAB.
Through guided exercises, attendees will learn how to efficiently model and simulate Wi-Fi 7 (IEEE 802.11be) networks, as well as study the coexistence of WLAN and Bluetooth systems.
The workshop enables participants to visualize network behavior and evaluate key performance metrics in realistic scenarios with minimal programming effort.


## Target Audience:
This workshop is intended for WLAN System Engineers and WLAN PHY/MAC Engineers who currently use, or wish to explore, WLAN and wireless network simulation capabilities within MATLAB.

## Learning Outcomes:

* Understand the working principles of wireless network simulators in MATLAB
* Simulate multinode WLAN systems by configuring application layer (APP), medium access control (MAC), and physical layer (PHY) parameters at each node
* Model both uplink (UL) and downlink (DL) communications between access points (APs) and stations (STAs)
* Visualize the allocation of time among Idle, Contention, Transmission, and Reception states for each node
* Record APP, MAC, and PHY statistics per node
* Implement multilink operations, including enhanced multi-link single radio (eMLSR) and simultaneous transmit and receive (STR) modes

This repo contains the files required to run the hands-on WLAN network modeling workshop in MATLAB&reg;. 
The "Exercise" files require code additions to run. The "Solution Scripts" files have the required code additions and run  
to completion.

The files enable the following exercises:  
1.  Exercise 1 - Operate the simulation engine, configure WLAN nodes, create a simple network, and see statistics  
2.  Exercise 2 - Configure traffic models, QoS, and model interference.   
3.  Exercise 3 - Implement custom channel model for WLAN Network
4.  Exercise 4 - Simulate a network with MLO nodes(WiFi-7)

## Setup 
To Run:
1. To conduct the workshop, use the "Exercise" files
2. To simply run the completed exercises, run the following files in MATLAB:
- EXPL1_WLAN_Simplest_Network.mlx
- EXPL2_WLAN_QoS_Interference.mlx
- EXPL3_WLAN_CustomChannelModel.mlx
- EXPL4_WLAN_MLO.mlx

### MathWorks Products (https://www.mathworks.com)

Requires the latest MATLAB release
- [Communications Toolbox Wireless Network Simulation Library;](https://www.mathworks.com/matlabcentral/fileexchange/119923-communications-toolbox-wireless-network-simulation-library)
- [WLAN Toolbox&trade;](https://www.mathworks.com/products/wlan.html)
- [Bluetooth Toolbox™](https://in.mathworks.com/products/bluetooth.html)
- [DSP System Toolbox&trade;](https://www.mathworks.com/products/dsp-system.html)
- [Communications Toolbox&trade;](https://www.mathworks.com/products/communications.html)
- [Signal Processing Toolbox&trade;](https://www.mathworks.com/products/signal.html)

### 3rd Party Products:
3p:
- None

## Getting Started 
See https://www.mathworks.com/help/wlan/system-level-simulation.html

## Examples
To see additional WLAN network simulation examples that perform  
similar workflows as those in the workshop, see:    
1.  https://www.mathworks.com/help/wlan/ug/getting-started-with-wlan-system-level-simulation-in-matlab.html
2.  https://www.mathworks.com/help/wlan/ug/802-11be-system-level-simulation-using-emlsr-multi-link-operation.html

## License
The license for the WLAN-Network-Modeling-Workshop is available in the LICENSE.TXT file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2025 The MathWorks, Inc.
