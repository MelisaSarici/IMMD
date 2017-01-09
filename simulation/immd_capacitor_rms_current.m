%% Capacitor Analytical RMS
M = 0.5;
cosphi = 0.9;
module = 4;
phase_dif = 90; % degrees

Vdc = 400; % Volts
Pout1 = 2e3; % W
Sout1 = Pout/(cosphi); % VA
Vll_rms = Vdc*0.612*M; % Volts
Iline = Sout1/(Vll_rms*sqrt(3)); % Amps
efficiency = 0.99;

Icrms = (0.275)*module*Iline*sqrt(2*M*(sqrt(3)/(4*pi) + cosphi^2*(sqrt(3)/pi-9*M/16)));
Idc = module*(3/(2*sqrt(2)))*M*Iline*cosphi/efficiency;
Icrms_perc = 100*Icrms/Idc;



%%
% 0.612 = sqrt(3/2)/2


%% Capacitor Selection
% Aluminium Electolytic

% Capacitance
% Rated voltage
% Iac_r (T,f)
% ESR (T,f)
% ESL
% Lifetime (T,Iac_r)
% Volume = D*L
% Rth_ca
% Weight


%% MAIN ALGORITHM

Icrms = zeros(10,10);
Cap = zeros(10,10);
Cap_max = zeros(1,10); 
for k = 1:10
    % Variables
    M = 0.1:0.1:1;
    
    % Inputs
    cosphi = 0.9;
    Vdc = 400; % V
    module = 4;
    phase_dif = 90; % degrees
    efficiency = 0.99;
    Tambient = 30; % C
    
    % Operational parameters
    Pout1 = M*2e3; % W
    Sout1 = Pout1/(cosphi); % VA
    Vll_rms = Vdc*0.612*M; % V
    Iarms = Sout1./(Vll_rms*sqrt(3)); % A
    Iapeak = Iarms*sqrt(2); % A
    
    % Select switching frequency
    fsw = k*10e3; % Hz
    
    % Constraints
    perc_ripple_c = 3; % percent
    volt_ripple_c = perc_ripple_c*0.01*Vdc; % V
    temp_max = 80; % C
    power_density_min = 10; % W/cm^3
    height_max = 50; % mm
    weight_max = 30; % g
    
    % Block 1 - RMS current
    interleaving_factor = 0.132*M+0.209;
    Icrms(k,:) = interleaving_factor*module.*Iarms.*sqrt(2*M.*(sqrt(3)/(4*pi) + cosphi^2*(sqrt(3)/pi-9*M/16)));
    Idc = module*(3/(2*sqrt(2))).*M.*Iarms*cosphi/efficiency;
    %Icrms_perc = 100*Icrms./Idc; % USE LATER
    
    % Block 2 - Required capacitance
    Icharge = module*Iapeak - Idc;
    %volt_ripple = Icharge*0.5*M/(fsw*C);
    Cap(k,:) = Icharge*0.5.*M/(volt_ripple_c*fsw); % F
    %Cap_select = ceil(Cap*1e5)*1e-5; % F
    
    Cap_max(k) = max(Cap(k,:));
    Icrms_max(k) = max(Icrms(k,:));
end

freq1 = 10e3:10e3:100e3;

figure;
plot(freq1/1e3,Cap_max*1e6,'bo-','Linewidth',1.5);
grid on;
set(gca,'FontSize',12);
xlabel('Switching frequency (kHz)','FontSize',12,'FontWeight','Bold')
ylabel('Capacitance requirement (uF)','FontSize',12,'FontWeight','Bold')

figure;
for k = 1:10
    plot(M,Cap(k,:)*1e6,'bo-','Linewidth',1.5);
    hold on;
end
hold off;
grid on;
set(gca,'FontSize',12);
xlabel('Modulation Index','FontSize',12,'FontWeight','Bold')
ylabel('Capacitance requirement (uF)','FontSize',12,'FontWeight','Bold')

figure;
plot(M,Icrms(1,:),'ro-','Linewidth',1.5);
grid on;
set(gca,'FontSize',12);
xlabel('Modulation Index','FontSize',12,'FontWeight','Bold')
ylabel('RMS current requirement (A)','FontSize',12,'FontWeight','Bold')


%% CAPACITOR SELECTION

required_capacitance = Cap_max(1)*1e6; % uF
required_rmscurrent = Icrms_max(1); % A

parallel_450 = zeros(1,numel(cap_select));
parallel_300 = zeros(1,numel(cap_select));
available_450 = ones(1,numel(cap_select));
available_300 = ones(1,numel(cap_select));
for m = 1:numel(cap_select)
    parallel_450(1,m) = ceil(required_capacitance/fpc_450v(m,1));
    rms_current_450(1,m) = parallel_450(1,m)*fpc_450v(m,5);
    parallel_300(1,m) = ceil(required_capacitance/(fpc_300v(m,1)/2));
    rms_current_300(1,m) = parallel_450(1,m)*fpc_300v(m,5)';
    if rms_current_450(1,m) < required_rmscurrent
        available_450(1,m) = 0;
    end
    if rms_current_300(1,m) < required_rmscurrent
        available_300(1,m) = 0;
    end
end

height_450 = fpc_450v(:,3); % mm
width_450 = fpc_450v(:,2); % mm
length_450 = fpc_450v(:,4); % mm
volume_450 = 1e-3*length_450.*width_450.*height_450.*parallel_450(1,:)'; % cm^3
power_density_450 = 2000./volume_450; % W/cm^3

height_300 = fpc_300v(:,3); % mm
width_300 = fpc_300v(:,2); % mm
length_300 = fpc_300v(:,4); % mm
volume_300 = 2*1e-3*length_300.*width_300.*height_300.*parallel_300(1,:)'; % cm^3
power_density_300 = 2000./volume_300; % W/cm^3

for m = 1:numel(cap_select)
    if power_density_450(m) < power_density_min
        available_450(1,m) = 0;
    end
    if power_density_300(m) < power_density_min
        available_300(1,m) = 0;
    end
    if height_450(m) > height_max
        available_450(1,m) = 0;
    end
    if height_300(m) > height_max
        available_300(1,m) = 0;
    end
end

ESR_450 = fpc_450v(:,6)*1e-3; % Ohm
ESR_300 = fpc_300v(:,6)*1e-3; % Ohm

Rth = 1e-3*50; % W/C
Ploss_450 = required_rmscurrent^2*ESR_450; % W
Tcore_450 = Rth*Ploss_450+Tambient; % C
Ploss_300 = required_rmscurrent^2*ESR_300; % W
Tcore_300 = Rth*Ploss_300+Tambient; % C

for m = 1:numel(cap_select)
    if Tcore_450(m) > temp_max
        available_450(1,m) = 0;
    end
    if Tcore_300(m) > temp_max
        available_300(1,m) = 0;
    end
end



%%
% Datasheet parameters (electrolytic)
% http://www.farnell.com/datasheets/1792285.pdf
Capacitance = 220e-6; % F
Diameter = 25; % mm
Length = 45; % mm
ESR_100_20 = 0.4; % Ohm
Iacmax_100_60 = 3.02; % A
Iacmax_100_85 = 2.32; % A
Rth = 20.19; % C/W
ESR_20 = ESR_100_20*0.7; % Ohm
ESR_80 = ESR_100_20*0.4; % Ohm
Iacmax_60 = Iacmax_100_60*1.37; % A
Iacmax_85 = Iacmax_100_85*1.37; % A
weight = 25; % g

Okey = zeros(1,5);

if Capacitance > Cap
    Okey(1) = 1;
end

Tcore = (Tambient+Icrms^2*Rth*0.32)/(1+Icrms^2*Rth*0.002); % C
ESR = 0.32-0.002*Tcore; % Ohm
Ploss = Icrms^2*ESR; % W
Iac_max = 4.7 - 0.028*Tcore; % A

if Iac_max > Icrms
    Okey(2) = 1;
end

if temp_max > Tcore
    Okey(3) = 1;
end

if height_max > Length
    Okey(4) = 1;
end

volume = pi*(Diameter/2)^2*Length*1e-3; % cm^3
power_density = Pout/volume; % W/cm^3

if power_density > power_density_min
    Okey(5) = 1;
end


%%
% Datasheet parameters (film)
% http://www.farnell.com/datasheets/1794158.pdf
series = 2;
parallel = 6;
Capacitance1 = 60e-6; % F
Capacitance = Capacitance1*(parallel/series); % F

%%
Width = 35; % mm
Length = 45; % mm
ESR_100_20 = 0.4; % Ohm
Iacmax_100_60 = 3.02; % A
Iacmax_100_85 = 2.32; % A
Rth = 20.19; % C/W
ESR_20 = ESR_100_20*0.7; % Ohm
ESR_80 = ESR_100_20*0.4; % Ohm
Iacmax_60 = Iacmax_100_60*1.37; % A
Iacmax_85 = Iacmax_100_85*1.37; % A
weight = 25; % g

Okey = zeros(1,5);

if Capacitance > Cap
    Okey(1) = 1;
end

Tcore = (Tambient+Icrms^2*Rth*0.32)/(1+Icrms^2*Rth*0.002); % C
ESR = 0.32-0.002*Tcore; % Ohm
Ploss = Icrms^2*ESR; % W
Iac_max = 4.7 - 0.028*Tcore; % A

if Iac_max > Icrms
    Okey(2) = 1;
end

if temp_max > Tcore
    Okey(3) = 1;
end

if height_max > Length
    Okey(4) = 1;
end

volume = pi*(Diameter/2)^2*Length*1e-3; % cm^3
power_density = Pout/volume; % W/cm^3

if power_density > power_density_min
    Okey(5) = 1;
end


%%
% Frequency factor of permissible ripple current Iac
freq1 = [50,60,70,80,90,100,200,300,400,500,600,700,800,900,1000,2000];
Iac_factor = [0.88,0.91,0.94,0.96,0.98,1,1.12,1.19,1.24,1.27,1.3,1.315,1.325,1.34,1.35,1.37];

num = numel(freq1);
N = 4;
P = polyfit(freq1,Iac_factor,N);
Iac_factor2 = zeros(1,num);

for k = 1:N+1
    Iac_factor2 = Iac_factor2+P(k)*freq1.^(N-k+1);
end

figure;
plot(freq1,Iac_factor,'ro-','Linewidth',1.5);
hold on;
plot(freq1,Iac_factor2,'bo-','Linewidth',1.5);
hold off;
grid on;
set(gca,'FontSize',12);
xlabel('Frequency','FontSize',12,'FontWeight','Bold')
ylabel('Iac factor','FontSize',12,'FontWeight','Bold')

%%
Iacc = 0;
frequency = 10:10:2000;
for k = 1:N+1
    Iacc = Iacc+P(k)*frequency.^(N-k+1);
end
figure;
plot(frequency,Iacc,'r -','Linewidth',1.5);
grid on;
set(gca,'FontSize',12);
xlabel('Frequency','FontSize',12,'FontWeight','Bold')
ylabel('Iac factor','FontSize',12,'FontWeight','Bold')

%%
% Frequency characteristics of ESR
freq11 = linspace(10,100,10);
freq22 = linspace(200,1000,9);
freq2 = zeros(1,19);
freq2(1:10) = freq11;
freq2(11:19) = freq22;
RMS_factor_20 = [1.7,1.6,1.5,1.46,1.3,1.23,1.17,1.08,1.03,1,0.85,0.78,0.76,0.75,0.74,0.73,0.72,0.71,0.7];

num = numel(freq2);
N = 7;
P = polyfit(freq2,RMS_factor_20,N);
RMS_factor2_20 = zeros(1,num);

for k = 1:N+1
    RMS_factor2_20 = RMS_factor2_20+P(k)*freq2.^(N-k+1);
end

figure;
plot(freq2,RMS_factor_20,'ro-','Linewidth',1.5);
hold on;
plot(freq2,RMS_factor2_20,'bo-','Linewidth',1.5);
hold off;
grid on;
set(gca,'FontSize',12);
xlabel('Frequency','FontSize',12,'FontWeight','Bold')
ylabel('RMS factor','FontSize',12,'FontWeight','Bold')
