function [Xo,io,Vo,soco] = battery_model(X0,SOC0,V0,P0,M0,t,T)
%
% Inputs : 
%    X0                initial state [Vc1,Vc2]'
%    SOC0              initial SOC
%    V0                initial voltage
%    P0                initial power
%    M0                initial deviation
%    t                 step index
%    T                 step interval
% Returns
%    io                optimal current [A]
%    Xo                next optimal state [Vc1,Vc2]'[V]
%    Vo                optimal voltage [V]
%    soco              optimal soc
L=xlsread('demand_pred');%Forecasted consumption profile
L_sim=xlsread('similar_days');%Similar day consumption profile
D_load=xlsread('dispatch_plan');%Forecasted consumption profile

%% Problem definition
% constraints
C_nom = 30; % Ah (battery nominal energy)
deltaB = 200; % max variation from a B setpoint to the following
%i_max,i_min
%v_max=2.7*15; % V Cell maximum voltage*15 in series
B_max = 100; % kW (max battery power)

% battery parameters
K_all=[592.2	625	652.9	680.2	733.2;
0.029	0.021	0.015	0.014	0.013;
0.095	0.075	0.09	0.079	0.199;
8930	9809	13996	9499	11234;
0.04	0.009	0.009	0.009	0.01;
909	2139	2482	2190	2505;
2.50E-03	4.90E-05	2.40E-04	6.80E-04	6.00E-04;
544.2	789	2959.7	100.2	6177.3];

K=size(K_all,1);
if (0<=SOC0)&&(SOC0<0.2)
   K=K_all(:,1);
elseif (0.2<=SOC0)&&(SOC0<0.4)
   K=K_all(:,2);
elseif (0.4<=SOC0)&&(SOC0<0.5)
   K=K_all(:,3);
elseif (0.6<=SOC0)&&(SOC0<0.8)
   K=K_all(:,4);
else
   K=K_all(:,5);  
end

E=K(1);
Rs=K(2);
R1=K(3);
C1=K(4);
R2=K(5);
C2=K(6);
%R3=K(7);
%C3=K(8);

% state matrix
A=[(R1*C1-T)/(R1*C1) 0;0 (R2*C2-T)/(R2*C2)];
B=[T/C1 T/C2]';
% state calculation

con=[];
obj=[];
i=sdpvar(10,1);%current
X=sdpvar(2,10);%state
v=sdpvar(10,1);%voltage
D=sdpvar(10,1);%voltage
soc=sdpvar(10,1);%soc
P=sdpvar(10,1);%power
con = con + (X(:,1) == ( A*X0+B*i(1) ));
con = con + (v(1) == (E-Rs*i(1)-[1 1]*X(:,1)) );
con = con + (soc(1) == (SOC0-10/3600/C_nom*i(1)) );
con = con + (P(1) == ((V0+v(1))/2*i(1)/1000) );
con = con + (P(1) <= B_max);
for j=2:10 %horizon=10
    con = con + (X(:,j) == (A*X(:,j-1)+B*i(j)) );
    con = con + (v(j) == E-Rs*i(j)-[1 1]*X(:,j));
    con = con + (soc(j) == soc(j-1)-10/3600/C_nom*i(j-1));
    con = con + (P(j) == ((v(j-1)+v(j))/2*i(j)/1000) );
    con = con + (P(j) <= B_max);
end

%con = con + ((v)<=(v_max*ones(10,1)));
con = con + ((0.2*ones(10,1))<=soc<=(0.8*ones(10,1)));
for j=1:10 %horizon=10
    D(j)=D_load(fix((t+j)/90)+1);
end
con = con + ( (3600/10*M0)<= (sum(D)- 10*P0 - sum(P)) );

obj = obj + (i'*i);

%% Run the solver and retrieve rounded optimal solution
% Specify solver settings and run solver
    diagnostics = solvesdp(con, obj,sdpsettings('verbose', 0));
    
    if diagnostics.problem == 0
       % Good! 
    else
        throw(MException('',yalmiperror(diagnostics.problem)));
    end


% Retrieve and round optimal solution
    i_star = value(i);
    io = i_star(1);
    Xo = A*X0+B*io;              
    soco = SOC0-10/3600/C_nom*io;
    Vo= E-Rs*io-[1 1]*X0;

end