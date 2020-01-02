module eth_mac_conf #(
	parameter PAUSE_FRAME_SOURCE_MAC = 48'h001122334455,
	parameter MTU_SIZE = 15'd1518
)(
	output wire [79:0] mac_tx_configuration_vector,
	output wire [79:0] mac_rx_configuration_vector
);

	// TX
	assign mac_tx_configuration_vector[79:32] = PAUSE_FRAME_SOURCE_MAC;
	assign mac_tx_configuration_vector[31] = 1'b0;
	assign mac_tx_configuration_vector[30:16] = MTU_SIZE;
	assign mac_tx_configuration_vector[15] = 1'b0;
	assign mac_tx_configuration_vector[14] = 1'b0;
	assign mac_tx_configuration_vector[13:11] = 3'b0;
	assign mac_tx_configuration_vector[10] = 1'b0;  // DIC enable
	assign mac_tx_configuration_vector[ 9] = 1'b0;
	assign mac_tx_configuration_vector[ 8] = 1'b0;
	assign mac_tx_configuration_vector[ 7] = 1'b0;
	assign mac_tx_configuration_vector[ 6] = 1'b0;
	assign mac_tx_configuration_vector[ 5] = 1'b0;
	assign mac_tx_configuration_vector[ 4] = 1'b1;  // jumbo frame enable
	assign mac_tx_configuration_vector[ 3] = 1'b0;
	assign mac_tx_configuration_vector[ 2] = 1'b0;  // VLAN enable
	assign mac_tx_configuration_vector[ 1] = 1'b1;  // TX enable
	assign mac_tx_configuration_vector[ 0] = 1'b0;

	// RX
	assign mac_rx_configuration_vector[79:32] = PAUSE_FRAME_SOURCE_MAC;
	assign mac_rx_configuration_vector[31] = 1'b0;
	assign mac_rx_configuration_vector[30:16] = MTU_SIZE;
	assign mac_rx_configuration_vector[15] = 1'b0;
	assign mac_rx_configuration_vector[14] = 1'b0;
	assign mac_rx_configuration_vector[13:11] = 3'b0;
	assign mac_rx_configuration_vector[10] = 1'b0;
	assign mac_rx_configuration_vector[ 9] = 1'b1;  // frame length check disable
	assign mac_rx_configuration_vector[ 8] = 1'b1;  // Length/Type error check disable
	assign mac_rx_configuration_vector[ 7] = 1'b0;
	assign mac_rx_configuration_vector[ 6] = 1'b0;
	assign mac_rx_configuration_vector[ 5] = 1'b0;
	assign mac_rx_configuration_vector[ 4] = 1'b1;  // jumbo frame enable
	assign mac_rx_configuration_vector[ 3] = 1'b0;
	assign mac_rx_configuration_vector[ 2] = 1'b0;  // VLAN enable
	assign mac_rx_configuration_vector[ 1] = 1'b1;  // RX enable
	assign mac_rx_configuration_vector[ 0] = 1'b0;

endmodule

