clear; close all; clc;
%yalmip('clear');
%addpath('./battery_model')%load battery state model
%battery_model
%load battery state model
X0=[0.01 0.01]';
SOC0=0.5;
V0=20;
P0=0.001;
M0=0.2;
t=600;
T=10;
[Xo,io,Vo,soco]=battery_model(X0,SOC0,V0,P0,M0,t,T);