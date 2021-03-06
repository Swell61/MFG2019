clc
clear
T=30; % horizon

numStates = 2; % 0 = healthy 1 = infected
% numActions = 1; % Couldn't see this being used anywhere
q = 0.9;

discountFactorInfHoriz = 0.9; % discount factor for infinite horizon reward.
discountFactorEquilibUpdate = 1; % discount factor for equilibrium update. It dampens the step size

N=40; %resolution for g space
g1v=(0:N)*(1/N); % Population of healthy nodes
xv=0:1/(numStates-1):1;

results=[];
p1Lm=0.5*ones(1,N+1); % they are symmetric
p1Hm=zeros(1,N+1);

u1Lm=zeros(1,N+1);
u1Hm=zeros(1,N+1);

k=0.2; % k + zt(1) = risk of being infected
L=0.5; % Lambda - cost of repair

for t=1:T % 2. For t = T, T − 1, . . . 1, ∀ z t
    t % DISPLAY
    p1Lm_n=zeros(1,N+1);
    p1Hm_n=zeros(1,N+1);
    u1Lm_n=zeros(1,N+1);
    u1Hm_n=zeros(1,N+1);
    
    parfor i1=1:length(g1v)
        g1=g1v(i1);  
        
        % Initial equilibrium guess
        p1L = p1Lm(i1); % Probability of doing nothing given ith node is healthy
        p1H = p1Hm(i1); % Probability of repairing given ith node is unhealthy
        
        err = 1;
        count = 0;
        
        while err > 1e-5 || count <=1000 % Policy iteration
            count = count+1;
            %z_n = z_t(1)*(1-p1L)*Q_x(1|1,1,z_t) + z_t(1)*p1L*Q_x(1|1,2,z_t) + z_t(2)*(1-p1H)*Q_x(1|2,1,z_t)+ z_t(2)*p1H*Q_x(1|2,2,z_t);
            g1_n = g1*(1-p1L)*(1-q) + g1*p1L*1 + 0+ (1-g1)*p1H*1;

            [V1L]=reward2go_0_inf(g1v,g1_n,u1Lm);
            [V1H]=reward2go_0_inf(g1v,g1_n,u1Hm);
            
            % User 1 state L
            u1L_0 = 0 + discountFactorInfHoriz * ((1-q)*V1L + q*V1H) ;
            u1L_1 = -L + discountFactorInfHoriz * V1L ;
            u1L_s = (1-p1L)*u1L_0 + p1L*u1L_1;
            phi1L_0 = discountFactorEquilibUpdate*max( 0, u1L_0 - u1L_s);
            phi1L_1 = discountFactorEquilibUpdate*max( 0, u1L_1 - u1L_s);
            p1L_n = (p1L + phi1L_1)/ (1 + phi1L_0 + phi1L_1 ); % Eq 37
            
            % User 1 , state H
            u1H_0 = -(k+1-g1)+ discountFactorInfHoriz*(V1H ) ;
            u1H_1 = -(k+1-g1)-L+ discountFactorInfHoriz*(V1L) ;
            u1H_s =  (1-p1H)* u1H_0 +  (p1H)* u1H_1;
            phi1H_0 = discountFactorEquilibUpdate*max( 0, u1H_0 - u1H_s);
            phi1H_1 = discountFactorEquilibUpdate*max( 0, u1H_1 - u1H_s);
            p1H_n = (p1H + phi1H_1)/ (1 + phi1H_0 + phi1H_1 ); % Eq 37

            err = norm([p1L p1H ] - [p1L_n p1H_n ]);
            

            p1L = p1L_n;
            p1H = p1H_n;
            
        end
        
        g1_n = g1*(1-p1L)*(1-q) + g1*p1L*1 + 0+ (1-g1)*p1H*1;
       [V1L]=reward2go_0_inf(g1v,g1_n,u1Lm);
       [V1H]=reward2go_0_inf(g1v,g1_n,u1Hm);

        % User 1 state L
        u1L_0 = 0 + discountFactorInfHoriz* ((1-q)*V1L + q*V1H) ;
        u1L_1 = -L + discountFactorInfHoriz* V1L ;

        % User 1 , state H
        u1H_0 = -(k+1-g1)+ discountFactorInfHoriz*(V1H ) ;
        u1H_1 = -(k+1-g1)-L+ discountFactorInfHoriz*(V1L) ;
        
        u1L = (1-p1L) * u1L_0 + p1L * u1L_1;
        u1H = (1-p1H)* u1H_0 +  (p1H)* u1H_1;
        
        p1Lm_n(i1)=p1L;
        p1Hm_n(i1)=p1H;
        
        u1Lm_n(i1)=u1L;
        u1Hm_n(i1)=u1H;
        
    end

    p1Lm=p1Lm_n;
    p1Hm=p1Hm_n;
    
    u1Lm=u1Lm_n;
    u1Hm=u1Hm_n;
 
end

figure
plot(g1v,p1Lm)
grid on
figure
plot(g1v,p1Hm)
gridon
figure
plot(g1v,u1Lm)
gridon
figure
plot(g1v,u2Hm)
gridon
