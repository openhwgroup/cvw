%
% Clear all variables and screen
clear
clf
% Define the number of bits (input Dividend)
n = 4;
%
% Define Divisor Range
% Normalized Floating Point [Dmin,Dmax] = [1,2]
% Normalized Fixed Point    [Dmin, Dmax] =[1/2,1]
%
Dminimum = 1.0/2;
Dmaximum = 2.0/2;
% Define an ulp
ulp = 2^(-n);
% radix = beta
beta  = 4;
% rho = redundancy factor -> SHOULD ALWAYS BE >= THAN 1/2
%
% SD representations have alpha < beta - 1
%
% alpha = ceil(beta/2)  minimially redundant  
% alpha = beta -1       maximally redundant (rho = 1)
% alpha = (beta-1)/2    nonredundant
% alpha > beta - 1      over-redundant
% 
rho = 2/3;
% Calculation of max digit set
alpha = rho*(beta-1);
% Da contains digit set
q = [];
for i = -alpha:alpha
  q = [q; i];
end
% 4r(i-1)/D values
hold on
% figure(1)
grid off
for i = 1:length(q)
  x = -rho+q(i):ulp:rho+q(i);
  % Plot redundancy (overlap) Positive
  z = [rho+q(i),rho+q(i)];
  y = [x(length(x))-q(i),0];
  % Plot redundancy (overlap) Negative
  if (i ~= length(q))
    w = [-rho+q(i+1)-q(i+1),0];
    u = [-rho+q(i+1),-rho+q(i+1)];
    % plot(u,w,'b')
  end
  % plot(x,x-q(i))
  % plot(z,y,'r')

end
% title('Robertson Diagram for Radix-4 SRT Divison')

Np   = 3;
Nd   = 3;
Dmin = Dminimum;
Dmax = Dmaximum;
ulpd = 2^(-Nd);
ulpp = 2^(-Np);

%
% Plot Atkins P-D plot
% Normalized Floating Point [Dmin,Dmax] = [1,2]
% Normalized Fixed Point    [Dmin, Dmax] =[1/2,1]
%
Dmin = Dminimum;
Dmax = Dmaximum;
for i = 1:length(q)
  D = Dmin:ulpd:Dmax;
  P1 = (rho+q(i))*D;
  P2 = (-rho+q(i))*D;
  hold on
  p1 = plot(D,P1,'b');
  p2 = plot(D,P2,'r');
  axis([Dmin Dmax -beta*rho*Dmaximum beta*rho*Dmaximum])
  xticks(D)
  p1.LineWidth = 2.0;
  p2.LineWidth = 2.0;
end

% Let's make x axis binary
D = Dmin:ulpd:Dmax;
j = [];
for i=1:length(D)
    j = [j disp_bin(D(i), 1, 3)];
end
yk = [];
yk2 = [];
for i=-2.5:0.5:2.5;
    yk = [yk disp_bin(i, 3, 3)];
    yk2 = [yk2 i];
end
xtickangle(90)
xticklabels(j)
yticklabels(yk)

% Let's draw allow points on PD plot
% Positive Portions
index = 1;
i = 0:ulpp:rho*beta*Dmaximum;
for j = Dmin:ulpd:Dmax
  plot(j*ones(1,length(i)),i,'k');
end

j = Dmin:ulpd:Dmax;
for i = 0:ulpp:rho*beta*Dmaximum
  plot(j,i*ones(length(j)),'k');
end

% Negative Portions
index = 1;
i = 0:-ulpp:rho*-beta*Dmaximum;
for j = Dmin:ulpd:Dmax
  plot(j*ones(1,length(i)),i,'k');
end

j = Dmin:ulpd:Dmax;
for i = 0:-ulpp:-rho*beta*Dmaximum
  plot(j,i*ones(length(j)),'k');
end

% Labels and Printing
xlh = xlabel(['Divisor (d)']);
xlh.Position(2) = xlh.Position(2) - 0.1;
xlh.FontSize = 18;
ylh = ylabel(['P = 4 \cdot w_i']);
ylh.Position(1) = ylh.Position(1)-0.02;
ylh.FontSize = 18;

% Containment Values (placed manually although not bad)
m2 = [5/6 1.0 5/4 11/8 11/8];
m1 = [1/4 1/4 1/2 1/2 1/2];
m0 = [-1/4 -1/4 -1/2 -1/2 -1/2];
m1b = [-5/6 -1 -5/4 -11/8 -11/8];
x2 = Dmin:ulpd:Dmax;
s2 = stairs(x2, m2);
s2.Color = '#8f08d1';
s2.LineWidth = 3.0;
s1 = stairs(x2, m1);
s1.Color = '#8f08d1';
s1.LineWidth = 3.0;
s0 = stairs(x2, m0);
s0.Color = '#8f08d1';
s0.LineWidth = 3.0;
s1b = stairs(x2, m1b);
s1b.Color = '#8f08d1';
s1b.LineWidth = 3.0;

% Place manually Quotient (ugh)
j = Dmin+ulpd/2:ulpd:Dmax;
i = rho*beta*Dmaximum-ulpp*3/4:-ulpp:-rho*beta*Dmaximum;
text(j(1), i(1), '2')
text(j(1), i(2), '2')
text(j(1), i(3), '2')
text(j(1), i(4), '2')
text(j(1), i(5), '2')
text(j(1), i(6), '2')
text(j(1), i(7), '2')
text(j(1), i(8), '2')
text(j(1), i(9), '2')
text(j(1), i(10), '2')
text(j(1), i(11), '2')
text(j(1), i(12), '2')
text(j(1), i(13), '2')
text(j(1), i(14), '2')
error1 = text(j(1), i(15), 'Full Precision', 'FontSize', 16);
text(j(1), i(16), '1')
text(j(1), i(17), '1')
text(j(1), i(18), '1')
text(j(1), i(19), '1')
text(j(1), i(20), '0')
text(j(1), i(21), '0')
text(j(1), i(22), '0')
text(j(1), i(23), '0')
text(j(1), i(24), '-1')
text(j(1), i(25), '-1')
text(j(1), i(26), '-1')
text(j(1), i(27), '-1')
error2 = text(j(1), i(28), 'Full Precision', 'FontSize', 16);
text(j(1), i(29), '-2')
text(j(1), i(30), '-2')
text(j(1), i(31), '-2')
text(j(1), i(32), '-2')
text(j(1), i(33), '-2')
text(j(1), i(34), '-2')
text(j(1), i(35), '-2')
text(j(1), i(36), '-2')
text(j(1), i(37), '-2')
text(j(1), i(38), '-2')
text(j(1), i(39), '-2')
text(j(1), i(40), '-2')
text(j(1), i(41), '-2')
text(j(1), i(42), '-2')

text(j(2), i(1), '2')
text(j(2), i(2), '2')
text(j(2), i(3), '2')
text(j(2), i(4), '2')
text(j(2), i(5), '2')
text(j(2), i(6), '2')
text(j(2), i(7), '2')
text(j(2), i(8), '2')
text(j(2), i(9), '2')
text(j(2), i(10), '2')
text(j(2), i(11), '2')
text(j(2), i(12), '2')
text(j(2), i(13), '2')
text(j(2), i(14), '1')
text(j(2), i(15), '1')
text(j(2), i(16), '1')
text(j(2), i(17), '1')
text(j(2), i(18), '1')
text(j(2), i(19), '1')
text(j(2), i(20), '0')
text(j(2), i(21), '0')
text(j(2), i(22), '0')
text(j(2), i(23), '0')
text(j(2), i(24), '-1')
text(j(2), i(25), '-1')
text(j(2), i(26), '-1')
text(j(2), i(27), '-1')
text(j(2), i(28), '-1')
text(j(2), i(29), '-1')
text(j(2), i(30), '-2')
text(j(2), i(31), '-2')
text(j(2), i(32), '-2')
text(j(2), i(33), '-2')
text(j(2), i(34), '-2')
text(j(2), i(35), '-2')
text(j(2), i(36), '-2')
text(j(2), i(37), '-2')
text(j(2), i(38), '-2')
text(j(2), i(39), '-2')
text(j(2), i(40), '-2')
text(j(2), i(41), '-2')
text(j(2), i(42), '-2')

text(j(3), i(1), '2')
text(j(3), i(2), '2')
text(j(3), i(3), '2')
text(j(3), i(4), '2')
text(j(3), i(5), '2')
text(j(3), i(6), '2')
text(j(3), i(7), '2')
text(j(3), i(8), '2')
text(j(3), i(9), '2')
text(j(3), i(10), '2')
text(j(3), i(11), '2')
text(j(3), i(12), '1')
text(j(3), i(13), '1')
text(j(3), i(14), '1')
text(j(3), i(15), '1')
text(j(3), i(16), '1')
text(j(3), i(17), '1')
text(j(3), i(18), '0')
text(j(3), i(19), '0')
text(j(3), i(20), '0')
text(j(3), i(21), '0')
text(j(3), i(22), '0')
text(j(3), i(23), '0')
text(j(3), i(24), '0')
text(j(3), i(25), '0')
text(j(3), i(26), '-1')
text(j(3), i(27), '-1')
text(j(3), i(28), '-1')
text(j(3), i(29), '-1')
text(j(3), i(30), '-1')
text(j(3), i(31), '-1')
text(j(3), i(32), '-2')
text(j(3), i(33), '-2')
text(j(3), i(34), '-2')
text(j(3), i(35), '-2')
text(j(3), i(36), '-2')
text(j(3), i(37), '-2')
text(j(3), i(38), '-2')
text(j(3), i(39), '-2')
text(j(3), i(40), '-2')
text(j(3), i(41), '-2')
text(j(3), i(42), '-2')

text(j(4), i(1), '2')
text(j(4), i(2), '2')
text(j(4), i(3), '2')
text(j(4), i(4), '2')
text(j(4), i(5), '2')
text(j(4), i(6), '2')
text(j(4), i(7), '2')
text(j(4), i(8), '2')
text(j(4), i(9), '2')
text(j(4), i(10), '2')
text(j(4), i(11), '1')
text(j(4), i(12), '1')
text(j(4), i(13), '1')
text(j(4), i(14), '1')
text(j(4), i(15), '1')
text(j(4), i(16), '1')
text(j(4), i(17), '1')
text(j(4), i(18), '0')
text(j(4), i(19), '0')
text(j(4), i(20), '0')
text(j(4), i(21), '0')
text(j(4), i(22), '0')
text(j(4), i(23), '0')
text(j(4), i(24), '0')
text(j(4), i(25), '0')
text(j(4), i(26), '-1')
text(j(4), i(27), '-1')
text(j(4), i(28), '-1')
text(j(4), i(29), '-1')
text(j(4), i(30), '-1')
text(j(4), i(31), '-1')
text(j(4), i(32), '-1')
text(j(4), i(33), '-2')
text(j(4), i(34), '-2')
text(j(4), i(35), '-2')
text(j(4), i(36), '-2')
text(j(4), i(37), '-2')
text(j(4), i(38), '-2')
text(j(4), i(39), '-2')
text(j(4), i(40), '-2')
text(j(4), i(41), '-2')
text(j(4), i(42), '-2')



print -dpng pd_bad.png





