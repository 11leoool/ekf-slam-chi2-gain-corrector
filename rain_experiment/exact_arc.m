function [pose1, G, V] = exact_arc(pose, u, dt)
% exact_arc  Exact constant-twist unicycle step + Jacobians (Thrun Table 5.3/7.4).
%
%   [pose1, G, V] = exact_arc(pose, u, dt)
%
% pose = [x; y; theta], u = [v; omega].
% G = d(pose1)/d(pose)   (3x3 motion Jacobian)
% V = d(pose1)/d(u)      (3x2 control Jacobian, maps Qu into pose space)

x = pose(1); y = pose(2); th = pose(3);
v = u(1);    w = u(2);

if abs(w) < 1e-9
    pose1 = [x + v*dt*cos(th);
             y + v*dt*sin(th);
             wrap_pi(th)];
    G = [1 0 -v*dt*sin(th);
         0 1  v*dt*cos(th);
         0 0  1];
    V = [dt*cos(th), 0;
         dt*sin(th), 0;
         0,          dt];
else
    s0 = sin(th);  s1 = sin(th + w*dt);
    c0 = cos(th);  c1 = cos(th + w*dt);
    pose1 = [x + (v/w)*(s1 - s0);
             y + (v/w)*(c0 - c1);
             wrap_pi(th + w*dt)];
    G = [1 0 (v/w)*(c1 - c0);
         0 1 (v/w)*(s1 - s0);
         0 0 1];
    V = [(s1 - s0)/w,  v*(s0 - s1)/w^2 + v*c1*dt/w;
         (c0 - c1)/w, -v*(c0 - c1)/w^2 + v*s1*dt/w;
         0,            dt];
end
end
