LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY goertzel IS
    GENERIC (
        N : POSITIVE := 135;
        SIG_BW : POSITIVE := 12;
        INT_BW : POSITIVE := 20;
        C_F : INTEGER := 18; -- Number of bits of fractional part of C
        FREQ : REAL := 150000.0; -- Target frequency in Hz
        SAMPLE_FREQ : REAL := 4000000.0 -- Sampling frequency in Hz
    );
    PORT (
        Clk_CI : IN STD_LOGIC;
        Rst_RBI : IN STD_LOGIC;
        Sample_SI : IN UNSIGNED(SIG_BW - 1 DOWNTO 0);
        Magnitude_sq_SO : OUT SIGNED(INT_BW - 1 DOWNTO 0); -- Signed output
        En_SI : IN STD_LOGIC;
        Done_SO : OUT STD_LOGIC
    );
END ENTITY goertzel;

ARCHITECTURE Behavioral OF goertzel IS
    CONSTANT LSB_TRUNC : INTEGER := 10; -- Truncation constant for LSB
    CONSTANT MAG_TRUNC : INTEGER := 11; -- Truncation constant for magnitude

    SIGNAL s0, s1_D, s2_D : SIGNED(INT_BW - 1 DOWNTO 0);
    SIGNAL Sum : SIGNED(INT_BW + LSB_TRUNC - 1 DOWNTO 0); -- Adjusted width for Sum
    SIGNAL temp_product1, temp_product2, temp_product3 : SIGNED(2 * INT_BW - 1 DOWNTO 0);
    SIGNAL temp_sum : SIGNED(2 * INT_BW - 1 DOWNTO 0);
    SIGNAL Active_V, Done_Flag : STD_LOGIC;
    SIGNAL magnitude_internal : SIGNED(2 * INT_BW - 1 DOWNTO 0); -- Intermediate signal with extended range
    SIGNAL magnitude_clamped : SIGNED(INT_BW - 1 DOWNTO 0); -- Clamped magnitude for final output
    CONSTANT C : SIGNED(INT_BW + C_F - 1 DOWNTO 0) := TO_SIGNED(509336, INT_BW + C_F); -- Manually calculated scaling constant
BEGIN
    PROCESS (Clk_CI)
    BEGIN
        IF rising_edge(Clk_CI) THEN
            IF Rst_RBI = '1' THEN
                s0 <= (OTHERS => '0');
                s1_D <= (OTHERS => '0');
                s2_D <= (OTHERS => '0');
                Sum <= (OTHERS => '0');
                magnitude_internal <= (OTHERS => '0');
                magnitude_clamped <= (OTHERS => '0');
                Done_SO <= '0';
                Active_V <= '0';
                Done_Flag <= '0';
            ELSE
                IF En_SI = '1' THEN
                    Active_V <= '1';
                END IF;

                IF Active_V = '1' THEN
                    -- Convert 12-bit unsigned input to 20-bit signed for internal processing
                    Sum <= resize(SIGNED('0' & Sample_SI), INT_BW + LSB_TRUNC) +
                           resize(SHIFT_RIGHT(C * s1_D, C_F - LSB_TRUNC), INT_BW + LSB_TRUNC) -
                           SHIFT_LEFT(resize(s2_D, INT_BW + LSB_TRUNC), LSB_TRUNC);
                    s0 <= Sum(INT_BW + LSB_TRUNC - 1 DOWNTO LSB_TRUNC); -- Corrected slicing operation
                     -- Reporting values for debugging
                    REPORT "Sample_SI: " & INTEGER'IMAGE(TO_INTEGER(Sample_SI));
                    REPORT "Sum: " & INTEGER'IMAGE(TO_INTEGER(Sum));
                    REPORT "s0: " & INTEGER'IMAGE(TO_INTEGER(s0));
                    REPORT "s1_D: " & INTEGER'IMAGE(TO_INTEGER(s1_D));
                    REPORT "s2_D: " & INTEGER'IMAGE(TO_INTEGER(s2_D));

                    -- Update s1_D and s2_D
                    s1_D <= s0;
                    s2_D <= s1_D;

                    -- Calculate magnitude squared
                    temp_product1 <= resize(s1_D * s1_D, 2 * INT_BW);
                    temp_product2 <= resize(s2_D * s2_D, 2 * INT_BW);
                    temp_product3 <= resize(SHIFT_RIGHT(s1_D * s2_D * C, C_F), 2 * INT_BW);
                    
                    temp_sum <= temp_product1 + temp_product2 - temp_product3;

                    -- Ensure non-negative magnitude
                    IF temp_sum < 0 THEN
                        magnitude_internal <= (OTHERS => '0');
                    ELSE
                        magnitude_internal <= temp_sum;
                    END IF;

                    -- Improved clamping to handle intermediate range values
                    magnitude_clamped <= resize(magnitude_internal(2 * INT_BW - 1 DOWNTO MAG_TRUNC), INT_BW);

                    -- Ensure magnitude_clamped is non-negative
                    IF magnitude_clamped < 0 THEN
                        magnitude_clamped <= (OTHERS => '0');
                    END IF;

                    -- Set Done_Flag
                    Done_Flag <= '1';
                ELSE
                    s1_D <= (OTHERS => '0');
                    s2_D <= (OTHERS => '0');
                END IF;

                -- Handle Done_Flag and Done_SO signaling
                IF Done_Flag = '1' THEN
                    Done_SO <= '1';
                    Done_Flag <= '0';
                ELSE
                    Done_SO <= '0';
                END IF;

                IF En_SI = '0' AND Active_V = '1' THEN
                    Active_V <= '0'; -- Reset Active_V to prevent further processing
                END IF;
            END IF;

            -- Report the value of Magnitude_sq_SO using the clamped magnitude
            REPORT "Magnitude_sq_SO: " & INTEGER'IMAGE(TO_INTEGER(magnitude_clamped));
        END IF;
    END PROCESS;

    -- Assign the clamped magnitude to the output port
    Magnitude_sq_SO <= magnitude_clamped;

END ARCHITECTURE Behavioral;