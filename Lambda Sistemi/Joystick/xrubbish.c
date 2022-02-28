
			
				
			{0x6040,0x00,RW_EE,2,{(rom unsigned char *)&dev_control_word}},					\\
			{0x6041,0x00,RO,2,{(rom unsigned char *)&dev_status_word}},						\\
			{0x6042,0x00,RO,1,{(rom unsigned char *)&device_mode}},							\\
			{0x6043,0x00,RW_EE,1,{(rom unsigned char *)&device_cntrl_mode}},					\\
			{0x604E,0x00,RO,2,{(rom unsigned char *)&ERROR_CODE}},							\\
			{0x604F,0x00,RO,1,{(rom unsigned char *)&device_local}},						\\
			{0x6050,0x00,CONST,4,{(rom unsigned char *)&rCO_DevHardwareVer}},				\\
			{0x6051,0x00,RW_EE,2,((unsigned char *)&vpoc_device_code_number)},					\\
			{0x6052,0x00,RW_EE,8,{(unsigned char *)&rCO_DevSerialNo}},						\\
			{0x6053,0x00,RW_EE,24,((unsigned char *)&rCO_DevDescription)},					\\
			{0x6054,0x00,CONST,24,((rom unsigned char *)&rCO_DevModelDescription)},			\\
			{0x6055,0x00,CONST,32,((rom unsigned char *)&rCO_DevModelURL)},					\\
			{0x6056,0x00,RW_EE,1,{(unsigned char *)&uIO_DevSetCode}},							\\
			{0x6057,0x00,CONST,24,((rom unsigned char *)&rCO_DeviceVendorName)},			\\
			{0x6200,0x00,RO,1,{(rom unsigned char *)&uLocalRcvBuffer[0]}},					\\

			{0x6300,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6300,0x01,RW,2,((unsigned char *)&vpoc_set_point)},							\\
			{0x6301,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6301,0x01,RO,2,((unsigned char *)&vpoc_actual_value)},					\\
			{0x6310,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6310,0x01,RO,2,((rom unsigned char *)&vpoc_demand_value)},				\\
			{0x6311,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6311,0x01,RW_EE,2,((unsigned char *)&vopc_demand_ref_value)},					\\
			{0x6314,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6314,0x01,RW_EE,2,((unsigned char *)&vpoc_demand_hold_set_point)},				\\
			{0x6320,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6320,0x01,RW_EE,2,((unsigned char *)&vpoc_demand_upper_limit)},				\\
			{0x6321,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6321,0x01,RW_EE,2,((unsigned char *)&vpoc_demand_lower_limit)},				\\
			{0x6322,0x00,RW_EE,4,((unsigned char *)&vpoc_demand_scaling_factor)},				\\
			{0x6323,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6323,0x01,RW_EE,2,((unsigned char *)&vpoc_demand_scaling_offset)},				\\
			{0x6324,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6324,0x01,RW_EE,2,((unsigned char *)&vpoc_demand_zero_correction_offset)},		\\
			{0x6330,0x00,RW_EE,1,((unsigned char *)&vpoc_demand_ramp_type)},					\\
			{0x6331,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6331,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_acceleration_time)},				\\
			{0x6332,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6332,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_acceleration_time_pos)},			\\
			{0x6333,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6333,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_acceleration_time_neg)},			\\
			{0x6334,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6334,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_deceleration_time)},				\\
			{0x6335,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6335,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_deceleration_time_pos)},			\\
			{0x6336,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6336,0x01,RW_EE,2,((unsigned char *)&vpoc_ramp_deceleration_time_neg)},			\\

			{0x6340,0x00,RW_EE,1,((unsigned char *)&vpoc_directional_dependent_gain_type)},	\\
			{0x6341,0x00,RW_EE,4,((unsigned char *)&vpoc_dir_dependent_gain_factor)},			\\
			{0x6342,0x00,RW_EE,1,((unsigned char *)&vpoc_dead_band_compensation_type)},		\\
			{0x6343,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6343,0x01,RW_EE,2,((unsigned char *)&vpoc_dead_band_compensation_A_side)},		\\
			{0x6344,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6344,0x01,RW_EE,2,((unsigned char *)&vpoc_dead_band_compensation_B_side)},		\\
			{0x6345,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6345,0x01,RW_EE,2,((unsigned char *)&vpoc_dead_band_compensation_threshold)},	\\
			{0x6346,0x00,RW_EE,1,((unsigned char *)&vpoc_characteristic)},						\\
			{0x6350,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6350,0x01,CONST,2,((rom unsigned char *)&vpoc_control_deviation)},			\\
			{0x6351,0x00,RW_EE,1,((unsigned char *)&vpoc_control_monitoring_type)},			\\
			{0x6352,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6352,0x01,RW_EE,2,((unsigned char *)&vpoc_control_monitoring_delay_time)},		\\
			{0x6353,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6353,0x01,RW_EE,2,((unsigned char *)&vpoc_control_monitoring_threshold)},		\\
			{0x6354,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6354,0x01,RW_EE,2,((unsigned char *)&vpoc_control_monitoring_upper_threshold)},	\\
			{0x6355,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6355,0x01,RW_EE,2,((unsigned char *)&vpoc_control_monitoring_lower_threshold)},	\\
			{0x6370,0x00,RW_EE,1,((unsigned char *)&vpoc_target_window_monitoring_type)},		\\
			{0x6371,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6371,0x01,RW_EE,2,((unsigned char *)&vpoc_target_monitoring_switch_on_time)},	\\
			{0x6372,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6372,0x01,RW_EE,2,((unsigned char *)&vpoc_target_monitoring_switch_off_time)},	\\
			{0x6373,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6373,0x01,RW_EE,2,((unsigned char *)&vpoc_target_monitoring_threshold)},		\\
			{0x6374,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6374,0x01,RW_EE,2,((unsigned char *)&vpoc_target_monitoring_upper_threshold)},	\\
			{0x6375,0x00,CONST,1,((rom unsigned char *)&const_vpoc_num_entries_1)},			\\
			{0x6375,0x01,RW_EE,2,((unsigned char *)&vpoc_target_monitoring_lower_threshold)},	\\
