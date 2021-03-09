%u1943002
%20/02/2021
%WM216 group coursework
%Part 2.1 car towing a caravan dynamic model
%=========================================================================

function [s,t] = CarTrailerModel(m1,m2,u,a1,a2,g,k,c,E,F,T)

%default values 
% assignin('base', 'm1' ,1400);   
% assignin('base', 'm2' ,600); 
% assignin('base', 'u' ,0.002); 
% assignin('base', 'a1' ,5); 
% assignin('base', 'a2' ,2.5); 
% assignin('base', 'g' ,9.8); 
% assignin('base', 'k' ,3*(1800 + 250*9)); 
% assignin('base', 'F' ,5000);
% assignin('base', 'c' ,0); 
% assignin('base', 'E' ,0); 


%% defining variables

%define all variables to base workspace
assignin('base', 'm1' ,m1);   
assignin('base', 'm2' ,m2); 
assignin('base', 'u' ,u); 
assignin('base', 'a1' ,a1); 
assignin('base', 'a2' ,a2); 
assignin('base', 'g' ,g); 
assignin('base', 'k' ,k); 
assignin('base', 'F' ,F);
assignin('base', 'c' ,c); 
assignin('base', 'E' ,E); 


%% Running Simulation
%run simulink simulation
simulation = sim('Car_Trailer_Model_Dampened', 'MaxStep','0.01','StopTime',T);

%% plotting graphs
%setting vaiables for plotting
car_dis = simulation.simout(:,1);
car_vel = simulation.simout(:,3);
car_acc = simulation.simout(:,5);

tra_dis = simulation.simout(:,2);
tra_vel = simulation.simout(:,4);
tra_acc = simulation.simout(:,6);

%defing variables for output of function
s = [car_vel,tra_vel];
t = simulation.tout;

%plotting simulation results
figure('Name', 'Car and Trailer', 'menubar', 'none')

subplot(3,1,1)
hold on
plot(simulation.tout,car_dis, 'r')
plot(simulation.tout,tra_dis, 'b')
title('Displacement')
legend('Car', 'Trailer')
xlabel('Time [sec]')
ylabel('displacment [m]')

subplot(3,1,2)
hold on
plot(simulation.tout,car_vel, 'r')
plot(simulation.tout,tra_vel, 'b')
title('Velocity')
legend('Car', 'Trailer')
xlabel('Time [sec]')
ylabel('Velocity [m/s]')

subplot(3,1,3)
hold on
plot(simulation.tout,car_acc, 'r')
plot(simulation.tout,tra_acc, 'b')
title('Acceleration')
legend('Car', 'Trailer')
xlabel('Time [sec]')
ylabel('Acceleration [m/s^2]')

end 