 library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity execute_stage is
    port(
        --Info from ID/EX register
        id_ex_instruction : in std_logic_vector(24 downto 0);
        id_ex_rs1_data : in std_logic_vector(127 downto 0);
        id_ex_rs2_data : in std_logic_vector(127 downto 0);
        id_ex_rs3_data : in std_logic_vector(127 downto 0);
        id_ex_rs1_address : in std_logic_vector(4 downto 0);
        id_ex_rs2_address : in std_logic_vector(4 downto 0);
        id_ex_rs3_address : in std_logic_vector(4 downto 0);

        --Forwarded data from EX/WB register
        ex_wb_fwd_data : in std_logic_vector(127 downto 0);
        ex_wb_fwd_address : in std_logic_vector(4 downto 0);
        ex_wb_fwd_wb : in std_logic;

        --Output info for EX/WB register
        output_rd_data : out std_logic_vector(127 downto 0);
        output_rd_address : out std_logic_vector(4 downto 0);
        output_rd_wb : out std_logic;

        --Info for result files
        sel_rs1 : out std_logic;
        sel_rs2 : out std_logic;
        sel_rs3 : out std_logic;
        data_rs1 : out std_logic_vector(127 downto 0);
        data_rs2 : out std_logic_vector(127 downto 0);
        data_rs3 : out std_logic_vector(127 downto 0);
        alu_result : out std_logic_vector(127 downto 0)	
    );
end execute_stage;

architecture structural of execute_stage is
	--Instantiation of forwarding unit
	component forwarding_unit is
	    port(
		id_ex_rs1_address : in std_logic_vector(4 downto 0);
		id_ex_rs2_address : in std_logic_vector(4 downto 0);
		id_ex_rs3_address : in std_logic_vector(4 downto 0);
		id_ex_opcode : in std_logic_vector(1 downto 0);
		ex_wb_rd_address : in std_logic_vector(4 downto 0);
		ex_wb_rd_wb : in std_logic;
		fwd_sel_rs1 : out std_logic;
		fwd_sel_rs2 : out std_logic;
		fwd_sel_rs3 : out std_logic	
	    );
	end component;
	
	--Instantiation of mux 2 to 1
	component mux_2to1 is 
	    port(
		sel : in std_logic;
		input_id_ex : in std_logic_vector(127 downto 0);
		input_ex_wb : in std_logic_vector(127 downto 0);
		output : out std_logic_vector(127 downto 0)		  
	    );
	end component;
	
	--Instantiation of ALU unit
	component alu_unit is
	    port(
		instruction : in std_logic_vector(24 downto 0);
		rs1 : in std_logic_vector(127 downto 0);
		rs2 : in std_logic_vector(127 downto 0);
		rs3 : in std_logic_vector(127 downto 0);
		rd : out std_logic_vector(127 downto 0); 
		rd_add : out std_logic_vector(4 downto 0);
		rd_write_back : out std_logic
	    );
	end component;	
	--Signals for forwarding unit
	signal fwd_sel_rs1 : std_logic;
	signal fwd_sel_rs2 : std_logic;
	signal fwd_sel_rs3 : std_logic;
	--Signals for MUXs
	signal mux_rs1_data : std_logic_vector(127 downto 0);
	signal mux_rs2_data : std_logic_vector(127 downto 0);
	signal mux_rs3_data : std_logic_vector(127 downto 0);
	--Signals for ALU unit
	signal alu_rd : std_logic_vector(127 downto 0);
	signal alu_rd_wb : std_logic;
	signal alu_rd_address: std_logic_vector(4 downto 0);
	
begin
	--Port Maps
	U_FWD : forwarding_unit
		port map(
		id_ex_rs1_address => id_ex_rs1_address,
		id_ex_rs2_address => id_ex_rs2_address,
		id_ex_rs3_address => id_ex_rs3_address,
		id_ex_opcode => id_ex_instruction(24 downto 23),
		ex_wb_rd_address => ex_wb_fwd_address,
		ex_wb_rd_wb => ex_wb_fwd_wb,
		fwd_sel_rs1 => fwd_sel_rs1,
		fwd_sel_rs2 => fwd_sel_rs2,
		fwd_sel_rs3 => fwd_sel_rs3
		);
		
	U_MUX_RS1 : mux_2to1
		port map(
		sel => fwd_sel_rs1,
		input_id_ex => id_ex_rs1_data,
		input_ex_wb => ex_wb_fwd_data,
		output => mux_rs1_data
	); 
	
	U_MUX_RS2 : mux_2to1
		port map(
		sel => fwd_sel_rs2,
		input_id_ex => id_ex_rs2_data,
		input_ex_wb => ex_wb_fwd_data,
		output => mux_rs2_data
	);
	
	U_MUX_RS3 : mux_2to1
		port map(
		sel => fwd_sel_rs3,
		input_id_ex => id_ex_rs3_data,
		input_ex_wb => ex_wb_fwd_data,
		output => mux_rs3_data
	);
	
	U_ALU : alu_unit
		port map(
		instruction => id_ex_instruction,
		rs1 => mux_rs1_data,
		rs2 => mux_rs2_data,
		rs3 => mux_rs3_data,
		rd => alu_rd,
		rd_write_back => alu_rd_wb,
		rd_add => alu_rd_address
	);
	--Output get signal info for result file
	sel_rs1 <= fwd_sel_rs1;
	sel_rs2 <= fwd_sel_rs2;
	sel_rs3 <= fwd_sel_rs3;
	data_rs1 <= mux_rs1_data;
	data_rs2 <= mux_rs2_data;
	data_rs3 <= mux_rs3_data;
	alu_result <= alu_rd;
	
end structural;
	
	
	
	
	
		
	
	

