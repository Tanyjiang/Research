function [J,t,x] = HighElevationCostFunction(p)

J = (checkFeasibility(p));
if J > 1e3
    [t,x(1:6)] = deal(0);
    return
end

if any(p<50) || any(p>220)
    J = 1e5*sum(abs(p-Saturate(p,50,220)));
    [t,x(1:6)] = deal(0);
    return
end
    

t1 = p(1);
t2 = p(2);
t3 = p(3);

dtr = pi/180;

x0 = [3540e3; -90.07*dtr; -43.90*dtr; 5505; -14.15*dtr; 4.99*dtr];
DR = 780;
CR = 0;

tf = 350;

r_eq = 3397e3;      % equatorial radius, m


sigma_min = 18.19*dtr;
sigma_max = 87.13*dtr;
fun = @(t) BankAngleProfile(t,t1,t2,t3,sigma_min,sigma_max);

opt = odeset('RelTol',1e-8,'AbsTol',1e-8);
[t,x] = ode45(@(T,X) PlannerDynamics(T,X,fun(T),x0,DR),[0 tf], x0,opt);

k_h = 0*5;
k_gamma = 0*(0.1*dtr)^-2;
k_d = 1;


h = x(end,1) - r_eq;
phi = x(end,3);
theta = x(end,2);
gamma = x(end,5);

%Distance metric using Haversine:
% [theta_T,phi_T] = FinalLatLon(x0(1),x0(2),x0(4),DR,CR);
% d = 2*r_eq*asin(sqrt( sin(0.5*(phi_T-phi)).^2 + cos(phi_T).*cos(phi).*sin(0.5*(theta_T-theta)).^2 ));

%Distance metric using range:
[dr,cr] = Range(x0(2),x0(3),x0(6),theta,phi);
d = norm([dr-DR,cr-CR]);
% d = abs(dr-DR);
J = (-h*k_h + k_gamma*gamma^2 + k_d*d);

end

function cost = checkFeasibility(t)
%Avoid computing the actual cost if the chosen times are infeasible. The
%cost will be 0 if the three switching times are feasible.
% boundViolation = (abs(t-Saturate(t,50,250)));
% if any(boundViolation)
%     cost = 1e9*sum(boundViolation);
% else
    cost = 0;
% end
    sig = (-diff(t));
%     for i = 1:2
%         if sig(i) > 0 && sig(i) < .001
%             sig(i) = 0;
%         end
%     end
        
    cost = cost + 1e6*(sum(sig+abs(sig))+sum(-t+abs(t)));
    if cost
        cost = max(cost,1e7);
    end

end