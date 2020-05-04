clear; close all; clc;
yalmip('clear');
%addpath('./integrators')
%% Load parameters
L=xlsread('demand_pred');%Forecasted consumption profile
L_sim=xlsread('similar_days');%Similar day consumption profile
K=xlsread('battery_parameters');%Estimated BESS voltage model parameters
n=size(L,1);%Interval numbers
L_avg=sum(L(:,2))/n*ones(n,1);%Flat demand
D=zeros(n,1);%Dispatch plan
deltaT=15;%Step length(min)

L_max=zeros(n,1);%Derive from similar days
L_min=zeros(n,1);%Derive from similar days
for i=1:n
    L_max(i)=max(L_sim(i,2:6));
    L_min(i)=min(L_sim(i,2:6));
end
SOE=zeros(n,1);%SOE profile
%% Problem definition
% Initialiation
SOE_0=0.5;

% Decision variables
F = sdpvar(n,1);

% Objective function
obj = (L(:,2)-L_avg+F)'*(L(:,2)-L_avg+F);

% Constraints
% Parameters constraints
B_max = 100; % kW (max battery power)
E_nom = 500; % kWh (battery nominal energy)
D_max = 500; % kW (max feeder power)
SOE_max=0.8;
SOE_min=0.2;

% Constraints
constr =[]; 
for i=1:n
    % Constraints on grid capacity
    constr = [constr, 0<=(L(i,2)+F(i))<=D_max];%ensure single direction
    % Constraints on battery capacity
    constr = [constr,-B_max<=(L(i,2)+F(i)-L_max(i))<=B_max];
    constr = [constr,-B_max<=(L(i,2)+F(i)-L_min(i))<=B_max];
    
    % Constraints on SOE
    constr = [constr,SOE_min<=(SOE_0+deltaT/60/E_nom*sum(F(1:i)))<=SOE_max];
    % Constraints on SOE(critical condition)
    %constr = [constr,SOE_min<=(SOE_0+deltaT/60/E_nom*( sum(L(1:i,2))+sum(F(1:i))-sum(L_min(1:i)) ))<=SOE_max];
    %constr = [constr,SOE_min<=(SOE_0+deltaT/60/E_nom*( sum(L(1:i,2))+sum(F(1:i))-sum(L_max(1:i)) ))<=SOE_max];
    
    % Constraints on SOE(similar days)
    for j=2:size(L_sim,2)
     constr = [constr,SOE_min<=(SOE_0+deltaT/60/E_nom*( sum(L(1:i,2))+sum(F(1:i))-sum(L_sim(1:i,j)) ))<=SOE_max];

    end
end
%% Run the solver and retrieve rounded optimal solution
% Specify solver settings and run solver
    diagnostics = solvesdp(constr, obj,sdpsettings('verbose', 0));
    
    if diagnostics.problem == 0
       % Good! 
    else
        throw(MException('',yalmiperror(diagnostics.problem)));
    end


% Retrieve and round optimal solution
    F_star = value(F);
    D=L(:,2)+F_star;
   for i=1:n
    SOE(i)=SOE_0+deltaT/60/E_nom*sum(F(1:i));
   end
%ops = sdpsettings('solver', 'mosek', 'verbose',0);
%diagnosis = optimize(constr, obj, ops);
%runtime = toc;


%% Plotting the results

figure
hold on; grid on;

o = ones(1,n);

subplot(4,1,1)
hold on; grid on;
plot(SOE,'-k','markersize',20,'linewidth',2);
plot(1:n,SOE_max*o,'r','linewidth',2)
plot(1:n,SOE_min*o,'r','linewidth',2)
ylabel('SOE')

subplot(4,1,2)
hold on; grid on;
plot(D,'-k','markersize',20,'linewidth',2);
plot(1:n,10*o,'r','linewidth',2)
plot(1:n,0*o,'r','linewidth',2)
ylabel('D')

subplot(4,1,3)
hold on; grid on;
plot(F_star,'-k','markersize',20,'linewidth',2);
plot(1:n,B_max*o,'r','linewidth',2)
plot(1:n,-B_max*o,'r','linewidth',2)
ylabel('F')

subplot(4,1,4)
hold on; grid on;
plot(L(:,2),'-k','markersize',20,'linewidth',2);
plot(1:n,max(L(:,2))*o,'r','linewidth',2)
plot(1:n,0*o,'r','linewidth',2)
ylabel('L')
