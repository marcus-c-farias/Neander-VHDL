----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.12.2023 12:30:21
-- Design Name: 
-- Module Name: main - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main is
    Port ( 
        clk, rst : in STD_LOGIC;
        Z, N : out STD_LOGIC;
        saidaNeander : out STD_LOGIC_VECTOR (7 downto 0);
        saidaPCNeander : out STD_LOGIC_VECTOR (7 downto 0) -- SERVE PARA TESTES
    );
end main;

architecture Behavioral of main is

-- Combinacioanl
-- MUX
signal selMux : std_logic := '0';
signal saidaMux : std_logic_vector (7 downto 0);

-- ULA
signal selULA : std_logic_vector(2 downto 0) := "001";
signal xValorULA, yValorULA, valorULA, saidaULA : std_logic_vector (7 downto 0);

-- DECODER
signal instrucao : std_logic_vector (15 downto 0); 
signal decoder : std_logic_vector (3 downto 0);

-- Sequencial
-- PC
signal cargaPC, incrementaPC : std_logic := '0';
signal valorPC, saidaPC : std_logic_vector (7 downto 0);

-- REM 
signal cargaREM : std_logic := '0';
signal valorREM, saidaREM : std_logic_vector (7 downto 0);

-- AC
signal cargaAC : std_logic := '0';
signal valorAC, saidaAC : std_logic_vector (7 downto 0);

-- NZ
signal cargaNZ, valorN, valorZ, saidaN, saidaZ : std_logic := '0';

-- RI
signal cargaRI : std_logic := '0';
signal valorRI, saidaRI : std_logic_vector (7 downto 4);

-- ESTADOS
type state_type is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
signal estado, proxEstado : state_type;

--  MEMORIA
signal escritaMemoria: STD_LOGIC := '0';
signal saidaMemoria: STD_LOGIC_VECTOR(7 downto 0);

COMPONENT memoria
    PORT(
        clk : IN STD_LOGIC; -- clock
        writeEnable : IN STD_LOGIC;
        address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dataIn : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dataOut :OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END COMPONENT;

begin

-- MAPEAMENTO DA MEMORIA
mem : memoria
    PORT MAP(
        clk => clk,
        writeEnable => escritaMemoria,
        address => saidaREM,
        dataIn => saidaAC,
        dataOut => saidaMemoria
    );

-- PC
process(clk, rst)
begin
    if rst = '1' then
        valorPC <= "00000000";
    elsif rising_edge(clk) then
        if cargaPC = '1' then valorPC <= saidaMemoria;
        elsif incrementaPC = '1' then valorPC <= valorPC + 1;
        else valorPC <= valorPC;
        end if;
    end if;
end process;
saidaPC <= valorPC;

-- REM
process(clk, rst)
begin
    if rst = '1' then
        valorREM <= "00000000";
    elsif rising_edge(clk) then
        if cargaREM = '1' then
            valorREM <= saidaMux;
        else
            valorREM <= valorREM;
        end if;
    end if;
end process;
saidaREM <= valorREM;

-- AC
process(clk, rst)
begin
    if rst = '1' then
        valorAC <= "00000000";
    elsif rising_edge(clk) then
        if cargaAC = '1' then
            valorAC <= saidaULA;
        else
            valorAC <= valorAC;
        end if;
    end if;
end process;
saidaAC <= valorAC;

-- RI
process(clk, rst)
begin
    if rst = '1' then
        valorRI <= "0000";
    elsif rising_edge(clk) then
        if cargaRI = '1' then
            valorRI <= saidaMemoria(7 downto 4);
        else
            valorRI <= valorRI;
        end if;
    end if;
end process;
saidaRI <= valorRI;

-- NZ
process(clk, rst)
begin
    if rst = '1' then
        valorN <= '0';
        valorZ <= '0';
    elsif rising_edge(clk) then
        if cargaNZ = '1' then
            valorN <= saidaAC(7);
            
            if saidaAC = "00000000" then
                valorZ <= '1';
            else
                valorZ <= '0';
            end if;
        end if; 
    end if;
end process;
saidaN <= valorN;
saidaZ <= valorZ;

-- MUX
process(selMux, saidaPC, saidaMemoria)
begin
    if selMux = '0' then
        saidaMux <= saidaPC;
    else
        saidaMux <= saidaMemoria;
    end if;
end process;

xValorULA <= saidaAC;
yValorULA <= saidaMemoria;

-- ULA
process(selULA, xValorULA, yValorULA)
begin

    case selULA is
        when "000" => valorULA <= (xValorULA + yValorULA);
        when "001" => valorULA <= (xValorULA and yValorULA);
        when "010" => valorULA <= (xValorULA or yValorULA);
        when "011" => valorULA <= (not xValorULA);
        when "100" => valorULA <= (yValorULA);
        when others => valorULA <= "00000000"; 
    end case;
end process;
saidaULA <= valorULA;

-- DECODER
process(decoder)
begin
    instrucao <= "0000000000000000";
    
    case decoder is
    when "0000" => instrucao(0) <= '1'; -- NOP
    when "0001" => instrucao(1) <= '1'; -- STA
    when "0010" => instrucao(2) <= '1'; -- LDA
    when "0011" => instrucao(3) <= '1'; -- ADD
    when "0100" => instrucao(4) <= '1'; -- OR
    when "0101" => instrucao(5) <= '1'; -- AND
    when "0110" => instrucao(6) <= '1'; -- NOT
    when "1000" => instrucao(8) <= '1'; -- JMP
    when "1001" => instrucao(9) <= '1'; -- JN
    when "1010" => instrucao(10) <= '1'; -- JZ
    when "1111" => instrucao(15) <= '1'; -- HLT  
    when others => instrucao <= "0000000000000000";
    end case;
end process;

-- FSM
process(rst, clk)
begin
    if rst = '1' then
        estado <= S0;
    elsif rising_edge(clk) then
        estado <= proxEstado;
    end if;
end process;

-- UNIDADE DE CONTROLE
process(estado, instrucao, saidaZ, saidaN)
begin

    -- zera as saidas
    cargaAC <='0';
    cargaNZ <='0';
    cargaPC <='0';
    selULA <="000";
    cargaRI <='0';
    incrementaPC <= '0';
    escritaMemoria <= '0';
    selMUX <= '0';
    cargaREM <='0';

    -- começo
    
    case estado is
        when S0 => 
            cargaREM <= '1';
            selMux <= '0';
            proxEstado <= S1;
        when S1 =>
            incrementaPC <= '1';
            proxEstado <= S2;
        when S2 =>
            cargaRI <= '1';
            proxEstado <= S3;
          
        when S3 =>
            if instrucao(6) = '1' then --NOT
                selULA <= "011";
                cargaAC <= '1';
                cargaNZ <= '1';
                proxEstado <= S0;
            elsif ((instrucao(9) = '1' and saidaN = '0') -- JZ ou JN para NZ = 0
                    or (instrucao(10) = '1' and saidaZ = '0')) then 
                incrementaPC <= '1';
                proxEstado <= S0;
            elsif instrucao(0) = '1' then  -- NOP
                proxEstado <= S0;
            elsif instrucao(15) = '1' then -- HLT
                proxEstado <= S8;
            else                           -- RESTO
                selMux <= '0';
                cargaREM <= '0';
                proxEstado <= S4;
            end if;    
               
        when S4 =>
        
            -- STA, LDA, ADD, OR, AND
            if (instrucao(1) = '1' or instrucao(2) = '1' or instrucao(3) = '1'
                or instrucao(4) = '1' or instrucao(5) = '1') then 
                incrementaPC <= '1';
            end if;
            proxEstado <= S5;
        when S5 =>
        
             -- STA, LDA, ADD, OR, AND
            if (instrucao(1) = '1' or instrucao(2) = '1' or instrucao(3) = '1'
                or instrucao(4) = '1' or instrucao(5) = '1') then 
                selMux <= '1';
                cargaREM <= '1';
                proxEstado <= S6;
            else
                cargaPC <= '1';
                proxEstado <= S0;
            end if;            
        when S6 =>
            proxEstado <= S7;
        when S7 =>
            
            if instrucao(1) = '1' then -- STA
                escritaMemoria <= '1';
            else
                cargaAC <= '1';
                cargaNZ <= '1';
                
                if instrucao(2) = '1' then --LDA
                    selULA <= "100"; -- Valor B
                elsif instrucao(3) = '1' then -- ADD
                    selULA <= "000"; 
                elsif instrucao(4) = '1' then -- OR
                    selULA <= "010"; 
                else
                    selULA <= "001"; -- AND
                end if;    
            end if;
            
            proxEstado <= S0;
        when S8 =>
            proxEstado <= S8;                
        when others => estado <= S0;
    end case;
end process;

Z <= saidaZ;
N <= saidaN;
saidaPCNeander <= saidaPC;
saidaNeander <= saidaMemoria;

end Behavioral;
