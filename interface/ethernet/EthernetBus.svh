/***********************************************************************************************************************
*                                                                                                                      *
* ANTIKERNEL v0.1                                                                                                      *
*                                                                                                                      *
* Copyright (c) 2012-2018 Andrew D. Zonenberg                                                                          *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@file EthernetBus.svh
	@author Andrew D. Zonenberg
	@brief Structure definitions for the Ethernet data bus

	This bus is used by most components of the TCP/IP stack. Some modules may add additional fields in parallel.

	Conventions
		start is asserted before, not simultaneous with, first assertion of data_valid
		bytes_valid is always 4 until last word in the packet, at which point it may take any value
		commit is asserted after, not simultaneous with, last assertion of data_valid
 */

`ifndef EthernetBus_h
`define EthernetBus_h

typedef struct packed
{
	logic		start;			//asserted for one cycle before a frame starts
	logic		data_valid;		//asserted when data is ready to be processed
	logic[2:0]	bytes_valid;	//when data_valid is set, indicated number of valid bytes in data
								//Valid bits are left aligned in data
								//1 = 31:24, 2 = 31:16, 3 = 31:8, 4 = 31:0
	logic[31:0]	data;			//actual packet content

	//These signals are only used for RX-side (coming from the NIC) traffic.
	//They are ignored in the TX direction and should not be written to.
	logic		commit;			//asserted for one cycle at end of packet if checksum was good
	logic		drop;			//asserted for one cycle to indicate packet is invalid and should be discarded
} EthernetBus;

`endif