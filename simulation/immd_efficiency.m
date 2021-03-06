%%
% IMMD efficiency calculation with GaN FETs
% Data from simulation and datasheet parameters will be used
% Later, analytical models will be developed for calculation and will be
% verified by simulation work

%%
% Simulation model

% step time
Ts = 1e-6; % sec
% modulation index
ma = 0.85;
% DC link voltage
Vdc = 400; % Volts
% Load
pf = 0.9;
Pout = 10e3; % VA
Sout = Pout/pf; % VA
efficiency = 0.99;
fsw = 10e3; % Hz
fout = 50; % Hz
wout = 2*pi*fout; % rad/sec
Vll_rms = ma*Vdc*0.612; % Volts
Iline = Sout/(Vll_rms*sqrt(3)); % Amps
Zload = Vll_rms/(Iline*sqrt(3)); % Ohms
Rload = Zload*pf; % Ohms
Xload = sqrt(Zload^2-Rload^2); % Ohms
Lload = Xload/wout; % Henries
R1 = 5; % Ohm
Rrefl = Vdc^2/(Pout/efficiency);
V1 = Vdc*(R1+Rrefl)/Rrefl; % V
Cdc = 50e-6; % F
sim('immd_eff1.slx');

%%
% Conduction loss
Rds_on = 18e-3; % Ohm
start = find(timeout==0.48);
end1 = find(timeout==0.5);
Econd_forward = 0; % J
Econd_reverse = 0; % J
for k = start:end1
    if Igann(k) >= 0
        Econd_forward = Econd_forward+Ts*Rds_on*Igann(k)^2; % J
    end
    if Igann(k) < 0
        Vsd(k) = (-Igann(k)+35)/17.5; % V
        Econd_reverse = Econd_reverse+Ts*Vsd(k)*(-Igann(k)); % J
    end
        
end
Pcond_forward1 = Econd_forward*50; % W
Pcond_reverse1 = Econd_reverse*50; % W
Pcond1 = Pcond_forward1+Pcond_reverse1; % W
Pcond = Pcond1*6; % W
eff_Pcond = 100*Pout/(Pout+Pcond); % percent 


%%
% Switching Loss


%%

figure;
subplot(2,1,1)
plot(timeout,Vsd,'b -','Linewidth',1.5);
grid on;
set(gca,'FontSize',12);
xlabel('Time (sec)','FontSize',12,'FontWeight','Bold')
ylabel('GaN voltage (V), GaN current (A)','FontSize',12,'FontWeight','Bold')
xlim([0.46 0.5]);
subplot(2,1,2)
plot(timeout,-Igann,'r -','Linewidth',1.5);
grid on;
set(gca,'FontSize',12);
xlabel('Time (sec)','FontSize',12,'FontWeight','Bold')
ylabel('GaN voltage (V), GaN current (A)','FontSize',12,'FontWeight','Bold')
xlim([0.46 0.5]);

%%

figure;
plot(timeout,Vgann,'r -','Linewidth',1.5);
hold on;
plot(timeout,Igann*10,'b -','Linewidth',1.5);
hold off;
grid on;
set(gca,'FontSize',12);
xlabel('Time (sec)','FontSize',12,'FontWeight','Bold')
ylabel('GaN voltage (V), GaN current (A)','FontSize',12,'FontWeight','Bold')
xlim([0.46 0.5]);

%%
Igan(n,l) = Igann(numel(Igann));
Vgan(n,1) = Vgann(numel(Vgann));