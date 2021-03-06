`timescale 1ns / 1ps
`default_nettype none
/***********************************************************************************************************************
*                                                                                                                      *
* ANTIKERNEL v0.1                                                                                                      *
*                                                                                                                      *
* Copyright (c) 2012-2017 Andrew D. Zonenberg                                                                          *
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
	@file
	@author Andrew D. Zonenberg
	@brief UART wrapper for RED TIN logic analyzer

	SIGNAL_ROM format:
		NOTE: Strings are null terminated. Use {"a", 8'h0} instead of the more concise "a\0" if you're targeting Vivado
		due to a bug re handling of embedded nulls:
		https://forums.xilinx.com/t5/Synthesis/Incorrect-synthesis-of-strings-containing-0x00-bytes-in-Vivado/td-p/783629

		16384'h0,							//Padding to ensure ROM is always 16Kbits in size
		"DEBUGROM", 8'h0, 8'h01, 8'h00,		//Magic header to indicate start of ROM
											//The 0-1-0 is sometimes flipped to 1-0-0 by Vivado synthesis,
											//for reasons unknown. If we see this, we know to flip all subsequent symbols
		32'd10000,							//Timebase, in picoseconds
		32'd512,							//Capture depth, in samples
		32'd128,							//Capture width, in samples
		{ "uart_tx_en", 8'h0, 8'h1, 8'h0 },	//name, width, format TBD (reserved zero)
		{ "uart_txd", 8'h0, 8'h8, 8'h0 },
 */
module RedTinUartWrapper #(
	parameter WIDTH 				= 128,
	parameter DEPTH 				= 512,
	parameter SYMBOL_ROM 			= 16384'h0,
	parameter UART_CLKDIV 			= 16'd868,		//115200 baud @ 100 MHz
	parameter KEYFRAME_INTERVAL		= 32'h00080000,
	parameter USE_EXT_TRIG			= 0
	)(

		//Internal clock, not necessarily used for capturing
		input wire				clk,

		//Data being sniffed
		input wire				capture_clk,
		input wire[WIDTH-1:0]	din,

		//Trigger/status signals
		input wire				ext_trig,
		output wire				trig_out,
		output wire				capture_done,

		//Bus to host PC
		input wire				uart_rx,
		output wire				uart_tx,

		//Indicates we're ready to start capturing (trigger input, etc)
		output reg				la_ready = 0
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Do some math to figure out how much data we need to move

	`include "../synth_helpers/clog2.vh"

	//The trigger data is one block of 32 32-bit words per 64 channels.
	//This is a total of 128 bytes per 64 channels or 2 bytes per channel.
	localparam BITSTREAM_SIZE = 2*WIDTH;
	localparam BITSTREAM_END = BITSTREAM_SIZE - 1;
	localparam BITSTREAM_ABITS = clog2(BITSTREAM_SIZE);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// The UART

	//8N1 configuration, no others supported
	reg			uart_tx_en		= 0;
	reg[7:0]	uart_tx_data	= 0;
	wire		uart_tx_active;
	wire		uart_rx_en;
	wire[7:0]	uart_rx_data;
	UART #(
		.OVERSAMPLE(1)
	) uart(
		.clk(clk),
		.clkdiv(UART_CLKDIV[15:0]),

		.tx(uart_tx),
		.tx_data(uart_tx_data),
		.tx_en(uart_tx_en),
		.txactive(uart_tx_active),

		.rx(uart_rx),
		.rx_data(uart_rx_data),
		.rx_en(uart_rx_en),
		.rxactive()
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Reshuffle the signal ROM until it fits in a 2Kx8 ROM, and swap bytes so we're ordered properly

	reg[7:0] symbols[2047:0];

	integer i;
	initial begin

		for(i=0; i<2048; i=i+1)
			symbols[i] <= SYMBOL_ROM[i*8 +: 8];

	end

	reg			symbol_rd_en	= 0;
	reg[10:0]	symbol_rd_addr	= 0;
	reg[7:0]	symbol_rd_data	= 0;

	always @(posedge clk) begin
		if(symbol_rd_en)
			symbol_rd_data		<= symbols[symbol_rd_addr];
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// The actual LA

	localparam 			ADDR_BITS = clog2(DEPTH);

	reg[31:0]			reconfig_din	= 0;
	reg					reconfig_ce		= 0;
	reg					reconfig_finish	= 0;

	reg					read_en			= 0;
	reg[ADDR_BITS-1:0]	read_addr		= 0;
	wire[WIDTH-1:0]		read_data;
	wire[31:0]			read_timestamp;

	//Number of bits required to count bytes in WIDTH
	localparam			BLOCK_BITS	 	= clog2(WIDTH) - 3;

	//Highest value for read_nbyte during readout
	localparam			BLOCK_MAX		= (WIDTH / 8) - 1;

	//Highest value for read_addr during readout
	localparam			ADDR_MAX		= DEPTH - 1'h1;

	reg[BLOCK_BITS-1:0]	read_nbyte		= 0;

	reg					la_reset		= 0;

	RedTinLogicAnalyzer #(
		.DEPTH(DEPTH),
		.DATA_WIDTH(WIDTH),
		.KEYFRAME_INTERVAL(KEYFRAME_INTERVAL),
		.USE_EXT_TRIG(USE_EXT_TRIG)
	) la (

		//Capture bus
		.capture_clk(capture_clk),
		.din(din),
		.ext_trig(ext_trig),
		.trig_out(trig_out),

		//Trigger bus
		.reconfig_clk(clk),
		.reconfig_din(reconfig_din),
		.reconfig_ce(reconfig_ce),
		.reconfig_finish(reconfig_finish),

		//Readout bus
		.read_clk(clk),
		.read_en(read_en),
		.read_addr(read_addr),
		.read_data(read_data),
		.read_timestamp(read_timestamp),

		//Command bus
		.done(capture_done),
		.reset(la_reset)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// UART command engine

	`include "RedTin_opcodes_localparam.vh"

	localparam STATE_IDLE				= 4'h0;
	localparam STATE_SYMTAB_0			= 4'h1;
	localparam STATE_SYMTAB_1			= 4'h2;
	localparam STATE_RECONFIGURE		= 4'h3;
	localparam STATE_RECONFIGURE_FINISH	= 4'h4;
	localparam STATE_TRIGGERED			= 4'h5;
	localparam STATE_READOUT_WAIT		= 4'h6;
	localparam STATE_READOUT_TIMESTAMP	= 4'h7;
	localparam STATE_READOUT_DATA		= 4'h8;
	localparam STATE_TX_WAIT			= 4'h9;

	reg[3:0]					state 	= STATE_IDLE;
	reg[BITSTREAM_ABITS-1:0]	bitpos	= 0;

	reg							notif_sent	= 0;

	//DEBUG
	reg[7:0]					ff_count = 0;
	reg[7:0]					sf_count = 0;
	reg[7:0]					zero_count = 0;
	reg[7:0]					other_count = 0;
	reg[7:0]					total_count = 0;

	always @(posedge clk) begin

		symbol_rd_en	<= 0;
		uart_tx_en		<= 8'h0;

		reconfig_ce		<= 0;
		reconfig_finish	<= 0;
		la_reset		<= 0;
		read_en			<= 0;

		if(reconfig_ce) begin
			total_count	<= total_count + 1'h1;
			if(reconfig_din == 32'h00000000)
				zero_count <= zero_count + 1'h1;
			else if(reconfig_din == 32'hffffffff)
				ff_count <= ff_count + 1'h1;
			else if(reconfig_din == 32'h7fffffff)
				sf_count <= sf_count + 1'h1;
			else
				other_count <= other_count + 1'h1;
		end

		case(state)

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// IDLE - sit around and wait for the opcode byte to come in

			STATE_IDLE: begin

				if(uart_rx_en) begin
					case(uart_rx_data)

						//Read symbol table - dump out the ROM
						REDTIN_READ_SYMTAB: begin
							symbol_rd_en		<= 1;
							symbol_rd_addr		<= 0;
							state				<= STATE_SYMTAB_0;
						end	//end REDTIN_READ_SYMTAB

						//Load trigger - take a bunch of LUT equations and shove them into the LA
						REDTIN_LOAD_TRIGGER: begin
							la_reset			<= 1;
							la_ready			<= 0;
							bitpos				<= 0;
							state				<= STATE_RECONFIGURE;
						end	//end REDTIN_LOAD_TRIGGER

						//Read data - take the stuff in the LA's buffer and spam it out to the host
						REDTIN_READ_DATA: begin
							read_en				<= 1;
							read_addr			<= 0;
							read_nbyte			<= 0;
							state				<= STATE_READOUT_WAIT;
						end	//end REDTIN_READ_DATA

						//Continue an existing readout operation
						REDTIN_READ_CONTINUE: begin
							read_en				<= 1;
							state				<= STATE_READOUT_WAIT;
						end	//end REDTIN_READ_DATA

						REDTIN_PING: begin
							uart_tx_en			<= 1;
							uart_tx_data		<= REDTIN_PING;
							state				<= STATE_TX_WAIT;
						end

						//Unknown opcode? Ignore it
						default: begin
						end
					endcase

				end

				//Scope just triggered! Send out an alert
				if(capture_done && !notif_sent) begin
					uart_tx_en					<= 1;
					uart_tx_data				<= REDTIN_TRIGGER_NOTIF;
					notif_sent					<= 1;
					state						<= STATE_TX_WAIT;
				end

			end	//end STATE_IDLE

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// SYMTAB - just spam the symbol table out the UART

			//Wait for read, then send it
			STATE_SYMTAB_0: begin
				if(!symbol_rd_en) begin
					uart_tx_en		<= 1;
					uart_tx_data	<= symbol_rd_data;
					state			<= STATE_SYMTAB_1;
				end
			end	//end STATE_SYMTAB_0

			//Wait for send, then read
			STATE_SYMTAB_1: begin
				if(!uart_tx_active && !uart_tx_en) begin

					//Not done? Keep going
					if(symbol_rd_addr != 'd2047) begin
						symbol_rd_en	<= 1;
						symbol_rd_addr	<= symbol_rd_addr + 1'h1;
						state			<= STATE_SYMTAB_0;
					end

					//Done, move along
					else
						state			<= STATE_IDLE;

				end
			end	//end STATE_SYMTAB_1

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// RECONFIGURE - load new trigger config

			//When rx_en is high, we have bitpos bytes ALREADY processed, plus a new one inbound right now
			STATE_RECONFIGURE: begin
				if(uart_rx_en) begin
					bitpos				<= bitpos + 1'h1;

					reconfig_din		<= { reconfig_din[23:0], uart_rx_data };

					//We read 3 bytes already, 4th is just arriving now
					if(bitpos[1:0] == 2'd3)
						reconfig_ce		<= 1;

					//Just got last byte? Go tell it to commit the changes
					if(bitpos == BITSTREAM_END)
						state			<= STATE_RECONFIGURE_FINISH;

				end
			end	//end STATE_RECONFIGURE

			STATE_RECONFIGURE_FINISH: begin
				reconfig_finish			<= 1;
				notif_sent				<= 0;
				la_ready				<= 1;
				uart_tx_data			<= REDTIN_LOAD_TRIGGER;
				uart_tx_en				<= 1;
				state					<= STATE_TX_WAIT;
			end	//end STATE_RECONFIGURE_FINISH

			STATE_TX_WAIT: begin
				if(!uart_tx_active && !uart_tx_en)
					state				<= STATE_IDLE;
			end	//end STATE_TX_WAIT

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// READOUT - dump data from the buffer out to the UART

			//Wait for read, then kick first timestamp byte out
			//(little endian order for easier processing on x86 hosts)
			STATE_READOUT_WAIT: begin
				if(!read_en) begin
					uart_tx_en			<= 1;
					uart_tx_data		<= read_timestamp[7:0];
					read_nbyte			<= 1;
					state				<= STATE_READOUT_TIMESTAMP;
				end
			end	//end STATE_READOUT_WAIT

			//Continue sending timestamp blocks
			STATE_READOUT_TIMESTAMP: begin
				if(!uart_tx_active && !uart_tx_en) begin
					uart_tx_en			<= 1;
					uart_tx_data		<= read_timestamp[read_nbyte[1:0]*8 +: 8];

					read_nbyte			<= read_nbyte + 1'h1;

					//If done with timestamp, start processing data
					if(read_nbyte >= 3) begin
						read_nbyte		<= 0;
						state			<= STATE_READOUT_DATA;
					end

				end
			end	//end STATE_READOUT_TIMESTAMP

			//Send the row of actual capture data
			STATE_READOUT_DATA: begin
				if(!uart_tx_active && !uart_tx_en) begin

					uart_tx_en			<= 1;
					uart_tx_data		<= read_data[read_nbyte*8 +: 8];
					read_nbyte			<= read_nbyte + 1'h1;

					//Done with the current row? Bump address and go back to idle until the PC asks for another word
					if(read_nbyte >= BLOCK_MAX) begin
						state		<= STATE_TX_WAIT;
						read_addr	<= read_addr + 1'h1;
					end

				end
			end	//end STATE_READOUT_DATA

		endcase

	end

endmodule
