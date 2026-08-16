library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.all;

entity pipeline_tb is
end pipeline_tb;

architecture behavioral of pipeline_tb is
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';

    	signal load_en : std_logic := '0';
    	signal load_addr : std_logic_vector(5 downto 0) := (others => '0');
    	signal load_data : std_logic_vector(24 downto 0) := (others => '0');
        signal fetch_en : std_logic := '0';
    
    	signal a_if_instruction : std_logic_vector(24 downto 0);
    	signal a_if_pc : std_logic_vector(5 downto 0);
    	signal a_if_id_instruction : std_logic_vector(24 downto 0);
    	signal a_id_rs1_addr : std_logic_vector(4 downto 0);
    	signal a_id_rs2_addr : std_logic_vector(4 downto 0);
    	signal a_id_rs3_addr : std_logic_vector(4 downto 0);
    	signal a_id_rd_addr : std_logic_vector(4 downto 0);
    	signal a_id_rs1_data : std_logic_vector(127 downto 0);
    	signal a_id_rs2_data : std_logic_vector(127 downto 0);
    	signal a_id_rs3_data : std_logic_vector(127 downto 0);
    	signal a_id_ex_instruction : std_logic_vector(24 downto 0);
        signal a_id_ex_rs1_data : std_logic_vector(127 downto 0);
	signal a_id_ex_rs2_data : std_logic_vector(127 downto 0);
	signal a_id_ex_rs3_data : std_logic_vector(127 downto 0);
	signal a_id_ex_rs1_addr : std_logic_vector(4 downto 0);
	signal a_id_ex_rs2_addr : std_logic_vector(4 downto 0);
	signal a_id_ex_rs3_addr : std_logic_vector(4 downto 0);
    	signal a_ex_sel_rs1 : std_logic;
    	signal a_ex_sel_rs2 : std_logic;
    	signal a_ex_sel_rs3 : std_logic;
        signal a_ex_data_rs1 : std_logic_vector(127 downto 0);
	signal a_ex_data_rs2 : std_logic_vector(127 downto 0);
	signal a_ex_data_rs3 : std_logic_vector(127 downto 0);
    	signal a_ex_alu_result : std_logic_vector(127 downto 0);
    	signal a_ex_rd_addr : std_logic_vector(4 downto 0);
    	signal a_ex_rd_wb : std_logic;
    	signal a_ex_wb_rd_data : std_logic_vector(127 downto 0);
    	signal a_ex_wb_rd_addr : std_logic_vector(4 downto 0);
    	signal a_ex_wb_rd_wb : std_logic;
    	signal a_wb_reg_file_data : std_logic_vector(127 downto 0);
    	signal a_wb_reg_file_addr : std_logic_vector(4 downto 0);
    	signal a_wb_reg_file_en : std_logic;
    
    	constant clk_period : time := 10 ns;

	type instr_array_t is array (0 to 63) of std_logic_vector(24 downto 0);
	signal program_size : integer := 0;
	file results_file : text;
	signal cycle_count : integer := 0;

	function string_to_slv25(s : string) return std_logic_vector is
        	variable result : std_logic_vector(24 downto 0);
    	begin
        	for i in 1 to 25 loop
            	if s(i) = '1' then
                	result(25 - i) := '1';
            	else
                	result(25 - i) := '0';
            	end if;
        	end loop;

        return result;
    end function;

begin
	UUT : entity pipeline
        	port map(
            		clk => clk,
            		reset => reset,
            		load_en => load_en,
            		load_addr => load_addr,
            		load_data => load_data,
			fetch_en => fetch_en,
            		a_if_instruction => a_if_instruction,
            		a_if_pc => a_if_pc,
            		a_if_id_instruction => a_if_id_instruction,
            		a_id_rs1_addr => a_id_rs1_addr,
            		a_id_rs2_addr => a_id_rs2_addr,
            		a_id_rs3_addr => a_id_rs3_addr,
            		a_id_rd_addr => a_id_rd_addr,
            		a_id_rs1_data => a_id_rs1_data,
            		a_id_rs2_data => a_id_rs2_data,
            		a_id_rs3_data => a_id_rs3_data,
            		a_id_ex_instruction => a_id_ex_instruction,
                    	a_id_ex_rs1_data => a_id_ex_rs1_data,
			a_id_ex_rs2_data => a_id_ex_rs2_data,
			a_id_ex_rs3_data => a_id_ex_rs3_data,
			a_id_ex_rs1_addr => a_id_ex_rs1_addr,
			a_id_ex_rs2_addr => a_id_ex_rs2_addr,
			a_id_ex_rs3_addr => a_id_ex_rs3_addr,
            		a_ex_sel_rs1 => a_ex_sel_rs1,
            		a_ex_sel_rs2 => a_ex_sel_rs2,
            		a_ex_sel_rs3 => a_ex_sel_rs3,
                    	a_ex_data_rs1 => a_ex_data_rs1,
        		a_ex_data_rs2 => a_ex_data_rs2,
        		a_ex_data_rs3 => a_ex_data_rs3,
            		a_ex_alu_result => a_ex_alu_result,
            		a_ex_rd_addr => a_ex_rd_addr,
            		a_ex_rd_wb => a_ex_rd_wb,
            		a_ex_wb_rd_data => a_ex_wb_rd_data,
            		a_ex_wb_rd_addr => a_ex_wb_rd_addr,
            		a_ex_wb_rd_wb => a_ex_wb_rd_wb,
            		a_wb_reg_file_data => a_wb_reg_file_data,
            		a_wb_reg_file_addr => a_wb_reg_file_addr,
            		a_wb_reg_file_en => a_wb_reg_file_en
        	);

	clk_gen : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
load_program : process
    file instr_file      : text open read_mode is "instructions.txt";
    variable line_buffer : line;
    variable instr_str   : string(1 to 25);
    variable expected    : instr_array_t := (others => (others => '0'));
    variable instr_count : integer := 0;
begin
    -- DON'T control reset here - let the reset process handle it
    -- Just wait for reset to complete
    wait until reset = '0';
    wait for 5 ns;
    
    -- Start loading
    load_en  <= '1';
    fetch_en <= '0';
    
    report "Starting to load instructions...";
    
    while not endfile(instr_file) loop
        readline(instr_file, line_buffer);
        read(line_buffer, instr_str);
        
        expected(instr_count) := string_to_slv25(instr_str);
        
        load_addr <= std_logic_vector(to_unsigned(instr_count, 6));
        load_data <= string_to_slv25(instr_str);
        
        report "Loading instruction " & integer'image(instr_count) & ": " & instr_str;
        
        wait until rising_edge(clk);
        wait for 1 ns;
        
        instr_count := instr_count + 1;
    end loop;
    
    -- Loading complete
    load_en  <= '0';
    program_size <= instr_count;
    file_close(instr_file);
    fetch_en <= '1';
    
    report "Loaded " & integer'image(instr_count) & " instructions. fetch_en = 1";
    wait;
end process;
	generate_results : process
		variable line_out : line;
		variable total_cycles : integer;
	begin
		wait until fetch_en = '1';
		wait for 10 ns;
		file_open(results_file, "results.txt", write_mode);

		wait until program_size > 0;
		--No stalling, 1 instruction per cycle 4 cycle for the pipeline to fill up N+3 to complete
		total_cycles := program_size + 3;
		for cycle in 0 to total_cycles - 1 loop
			wait until rising_edge(clk);
			wait for 1 ns;

			-- Cycle count
            		write(line_out, string'("Cycle: "));
            		write(line_out, cycle_count);
            		writeline(results_file, line_out);
            
            		-- IF Stage
            		write(line_out, string'("IF instruction: "));
            		hwrite(line_out, a_if_instruction);  -- Correct syntax
            		write(line_out, string'(", IF PC: "));
            		write(line_out, a_if_pc);
            		writeline(results_file, line_out);
        
            		-- IF/ID
            		write(line_out, string'("IF/ID reg instruction: "));
            		hwrite(line_out, a_if_id_instruction);
            		write(line_out, string'(", IF/ID reg PC: "));
            		write(line_out, a_if_pc);
            		writeline(results_file, line_out);
        
            		-- ID Addresses
            		write(line_out, string'("ID rs1 addr: "));
            		write(line_out, a_id_rs1_addr);
            		write(line_out, string'(", ID rs2 addr: "));
            		write(line_out, a_id_rs2_addr);
            		write(line_out, string'(", ID rs3 addr: "));
            		write(line_out, a_id_rs3_addr);
            		write(line_out, string'(", ID rd addr: "));
            		write(line_out, a_id_rd_addr);
            		writeline(results_file, line_out);
            
            		-- ID Data
            		write(line_out, string'("ID rs1 data: "));
            		hwrite(line_out, a_id_rs1_data);
            		write(line_out, string'(", ID rs2 data: "));
            		hwrite(line_out, a_id_rs2_data);
            		write(line_out, string'(", ID rs3 data: "));
            		hwrite(line_out, a_id_rs3_data);
            		writeline(results_file, line_out);
        
            		-- ID/EX
            		write(line_out, string'("ID/EX reg instruction: "));
            		hwrite(line_out, a_id_ex_instruction);
            		writeline(results_file, line_out);
            
            		write(line_out, string'("ID/EX rs1 data: "));
            		hwrite(line_out, a_id_ex_rs1_data);
            		write(line_out, string'(", ID/EX rs2 data: "));
            		hwrite(line_out, a_id_ex_rs2_data);
            		write(line_out, string'(", ID/EX rs3 data: "));
            		hwrite(line_out, a_id_ex_rs3_data);
            		writeline(results_file, line_out);
            
            		write(line_out, string'("ID/EX rs1 addr: "));
            		write(line_out, a_id_ex_rs1_addr);
            		write(line_out, string'(", ID/EX rs2 addr: "));
            		write(line_out, a_id_ex_rs2_addr);
            		write(line_out, string'(", ID/EX rs3 addr: "));
            		write(line_out, a_id_ex_rs3_addr);
            		writeline(results_file, line_out);
        
            		-- EX Forwarding Selects
            		write(line_out, string'("Sel rs1: "));
            		write(line_out, a_ex_sel_rs1);
            		write(line_out, string'(", Sel rs2: "));
            		write(line_out, a_ex_sel_rs2);
            		write(line_out, string'(", Sel rs3: "));
            		write(line_out, a_ex_sel_rs3);
            		writeline(results_file, line_out);
            
            		-- EX Muxed Data
            		write(line_out, string'("EX data rs1: "));
            		hwrite(line_out, a_ex_data_rs1);
            		write(line_out, string'(", EX data rs2: "));
            		hwrite(line_out, a_ex_data_rs2);
            		write(line_out, string'(", EX data rs3: "));
            		hwrite(line_out, a_ex_data_rs3);
            		writeline(results_file, line_out);
        
            		-- EX ALU Result
            		write(line_out, string'("ALU result: "));
            		hwrite(line_out, a_ex_alu_result);
            		writeline(results_file, line_out);
        
            		-- EX Destination
            		write(line_out, string'("EX rd addr: "));
            		write(line_out, a_ex_rd_addr);
            		write(line_out, string'(", EX write back: "));
            		write(line_out, a_ex_rd_wb);
            		writeline(results_file, line_out);
        
            		-- EX/WB
            		write(line_out, string'("EX/WB reg data: "));
            		hwrite(line_out, a_ex_wb_rd_data);
            		writeline(results_file, line_out);
            
            		write(line_out, string'("EX/WB reg addr: "));
            		write(line_out, a_ex_wb_rd_addr);
            		write(line_out, string'(", EX/WB write back: "));
            		write(line_out, a_ex_wb_rd_wb);
            		writeline(results_file, line_out);
        
            		-- WB Stage
            		write(line_out, string'("WB data: "));
            		hwrite(line_out, a_wb_reg_file_data);
            		writeline(results_file, line_out);
            
            		write(line_out, string'("WB addr: "));
            		write(line_out, a_wb_reg_file_addr);
            		write(line_out, string'(", WB enable: "));
            		write(line_out, a_wb_reg_file_en);
            		writeline(results_file, line_out);
                	write(line_out, string'("-----------------------------------"));
			
			writeline(results_file, line_out);
		end loop;
	file_close(results_file);
	end process;
	process
        	variable total_cycles : integer;
    	begin
        	reset <= '1';
        	wait for 20 ns;
        	reset <= '0';
        	wait until fetch_en = '1';
        	wait until program_size > 0;
        	total_cycles := program_size + 3;
        	wait for total_cycles * clk_period;
		report "Simulation completed successfully!" severity note;
        	wait;
    	end process;
end behavioral;
