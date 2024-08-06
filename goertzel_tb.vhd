library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
library STD;
use STD.TEXTIO.ALL;

entity goertzel_tb is
end entity goertzel_tb;

architecture Behavioral of goertzel_tb is

    component goertzel is
        generic (
            N : positive := 135;
            SIG_BW : positive := 12;
            INT_BW : positive := 20
        );
        port (
            Clk_CI : in std_logic;
            Rst_RBI : in std_logic;
            Sample_SI : in unsigned(SIG_BW - 1 downto 0);
            Magnitude_sq_SO : out signed(INT_BW - 1 downto 0);
            En_SI : in std_logic;
            Done_SO : out std_logic
        );
    end component;

    signal Clk_CI : std_logic := '0';
    signal Rst_RBI : std_logic := '1';
    signal Sample_SI : unsigned(11 downto 0) := (others => '0');
    signal Magnitude_sq_SO : signed(19 downto 0);
    signal En_SI : std_logic := '0';
    signal Done_SO : std_logic;

    constant Clk_Period : time := 10 ns;
    constant MAX_STRING_LENGTH : integer := 100;

    -- Helper function to pad strings
    function pad_string(input_str : string; target_length : integer) return string is
        variable padded_str : string(1 to target_length);
        variable i : integer;
    begin
        for i in input_str'range loop
            padded_str(i) := input_str(i);
        end loop;
        for i in input_str'length + 1 to target_length loop
            padded_str(i) := ' ';
        end loop;
        return padded_str;
    end function;

    -- Helper function to trim strings
    function trim(s : string) return string is
        variable result : string(1 to s'length);
        variable i, last_non_space : integer;
    begin
        last_non_space := s'length;
        for i in s'range loop
            result(i) := s(i);
            if s(i) /= ' ' then
                last_non_space := i;
            end if;
        end loop;
        return result(1 to last_non_space);
    end function;

    -- Extend the waveform name list with new frequencies
    type waveform_array is array (0 to 69) of string(1 to MAX_STRING_LENGTH);
constant waveform_list : waveform_array := (
    -- Sine Waves
    pad_string("sine_wave_150000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_150000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_150000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_150000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_150000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_149000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_149000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_149000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_149000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_149000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_151000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_151000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_151000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_151000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_151000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_5000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_5000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_5000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_5000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_5000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_200000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_200000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_200000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_200000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("sine_wave_200000Hz_120deg", MAX_STRING_LENGTH),
    
    -- Square Waves
    pad_string("square_wave_150000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("square_wave_150000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("square_wave_150000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("square_wave_150000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("square_wave_150000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("square_wave_16000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("square_wave_16000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("square_wave_16000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("square_wave_16000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("square_wave_16000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("square_wave_10000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("square_wave_10000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("square_wave_10000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("square_wave_10000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("square_wave_10000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("square_wave_200000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("square_wave_200000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("square_wave_200000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("square_wave_200000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("square_wave_200000Hz_120deg", MAX_STRING_LENGTH),
    
    -- Triangle Waves
    pad_string("triangle_wave_150000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_150000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_150000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_150000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_150000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_149000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_149000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_149000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_149000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_149000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_151000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_151000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_151000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_151000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_151000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_5000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_5000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_5000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_5000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_5000Hz_120deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_200000Hz_0deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_200000Hz_30deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_200000Hz_45deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_200000Hz_90deg", MAX_STRING_LENGTH),
    pad_string("triangle_wave_200000Hz_120deg", MAX_STRING_LENGTH)
);


begin
    UUT: goertzel
        port map (
            Clk_CI => Clk_CI,
            Rst_RBI => Rst_RBI,
            Sample_SI => Sample_SI,
            Magnitude_sq_SO => Magnitude_sq_SO,
            En_SI => En_SI,
            Done_SO => Done_SO
        );

    -- Clock generation process
    Clock_Process: process
    begin
        while true loop
            Clk_CI <= '1';
            wait for Clk_Period / 2;
            Clk_CI <= '0';
            wait for Clk_Period / 2;
        end loop;
    end process;

    Stimulus_Process: process
        variable file_line : line;
        variable var_data : integer;
        file infile : text;
        variable Sample_SI_var : unsigned(11 downto 0);
        variable var_expected : signed(19 downto 0);
        file expected_file : text;
        variable expected_line : line;
        variable expected_data : string(1 to MAX_STRING_LENGTH);
        variable waveform_name : string(1 to MAX_STRING_LENGTH);
        variable expected_value : integer;
    begin
        -- Initialize the setup
        wait for 100 ns;
        Rst_RBI <= '0';

        -- Enable the filter
        En_SI <= '1';

        -- Open expected results file
        file_open(expected_file, "D:/Microelectronics_HWSW Co-Design/S24_Homework_project/expected_results.txt", read_mode);

        -- Process each waveform file
        for i in waveform_list'range loop
            waveform_name := waveform_list(i);

            -- Open the waveform file
            file_open(infile, "D:/Microelectronics_HWSW Co-Design/S24_Homework_project/waveforms/" & trim(waveform_name) & ".txt", read_mode);

            -- Read and apply waveforms
            while not endfile(infile) loop
                readline(infile, file_line);
                read(file_line, var_data);
                Sample_SI_var := to_unsigned(var_data, Sample_SI_var'length);
                Sample_SI <= Sample_SI_var;
                wait for Clk_Period;
            end loop;
            file_close(infile);

            -- Wait for processing to complete
            wait for 100 ns;

            -- Read expected value
            while not endfile(expected_file) loop
                readline(expected_file, expected_line);
                read(expected_line, expected_data);
                if trim(expected_data(1 to waveform_name'length)) = trim(waveform_name) then
                    read(expected_line, expected_value);
                    exit;
                end if;
            end loop;

            -- Compare with expected result
            var_expected := to_signed(expected_value, Magnitude_sq_SO'length);
            assert resize(var_expected, Magnitude_sq_SO'length) = Magnitude_sq_SO
            report "FAIL, Expected Magnitude_sq_SO: " & integer'image(to_integer(var_expected)) &
                   " Actual: " & integer'image(to_integer(Magnitude_sq_SO))
            severity warning;
        end loop;

        file_close(expected_file);

        -- Disable the filter
        En_SI <= '0';

        wait;
    end process;

end architecture Behavioral;
