clear; close all; clc;
%yalmip('clear');
%addpath('./battery_model')%load battery state model
L_sim=xlsread('similar_days');%Similar day consumption profile
D=xlsread('dispatch_plan');%Forecasted consumption profile

%% Preliminaries
% Initial condition
X0 = [0; 0];
SOC0 = 0.5;
V0= 652.9;
P0=0;
M0=0;
t=0;
T=10;

V=zeros(8640,1);
SOC=zeros(8640,1);
I=zeros(8640,1);
M=zeros(8639,1);
B=zeros(8640,1);%battery real power
X=zeros(2,8640);%battery real power
% Horizon and step interval
N = 10; %horizon
T = 10; %[s]step interval

% Constraints
% Parameters constraints
B_max = 100; % kW (max battery power)
E_nom = 500; % kWh (battery nominal energy)
D_max = 500; % kW (max feeder power)
SOE_max=0.8;
SOE_min=0.2;
SOC_max=0.8;
SOC_min=0.2;

%profile calculation
for j=1:60
    if j==1
        [Xo,io,Vo,soco]=battery_model(X0,SOC0,V0,P0,M0,t,T); 
        X(:,j)=Xo;
        SOC(j)=soco;
        V(j)=Vo;
        I(j)=io;
        B(j)=(V0+V(j))/2*I(j)/1000*10/3600;
        t=t+1;
    else
        x0 = X(:,j-1);
        SOC0 = SOC(j-1);
        V0= V(j-1);
        P0= L_sim(fix((t)/90+1),2);%real
        M(j-1)=B(j-1)+L_sim(fix(t/90)+1,2)-D(fix(t/90)+1);%real
        M0=M(j-1);
        [Xo,io,Vo,soco]=battery_model(X0,SOC0,V0,P0,M0,t,T);
        X(:,j)=Xo;
        SOC(j)=soco;
        V(j)=Vo;
        I(j)=io;
        B(j)=(V0+V(j))/2*I(j)/1000*10/3600;
        t=t+1;
    end
end
%% Plotting the results

figure
hold on; grid on;

o = ones(1,8640);

subplot(3,1,1)
hold on; grid on;
plot(D,'-k','markersize',20,'linewidth',2);
plot(1:8640,10*o,'r','linewidth',2);
plot(1:8640,0*o,'r','linewidth',2);
ylabel('D');

subplot(3,1,2)
hold on; grid on;
plot(M,'-k','markersize',20,'linewidth',2);
plot(1:8640,10*o,'r','linewidth',2);
plot(1:8640,-10*o,'r','linewidth',2);
ylabel('M');

subplot(3,1,3)
hold on; grid on;
plot(SOC,'k','markersize',20,'linewidth',2);
plot(1:8640,SOC_max*o,'r','linewidth',2);
plot(1:8640,-SOC_min*o,'r','linewidth',2);
ylabel('SOC');