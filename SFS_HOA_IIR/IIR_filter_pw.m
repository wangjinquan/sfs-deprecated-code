function [OUT] = IIR_filter_pw(config)

% get angle of loudspeaker position
alpha_0=atan2( config.x0( 2,: ), config.x0( 1,: ) );

% get spatial band limitation  
L=length( config.x0 );
if mod( L,2 )
   N21 =  floor( L/2 );
   N22 = N21;
else
   N21 = L/2-1;
   N22 = L/2;
end

% allocate memory for impulse responses
imp_resp = zeros(config.N2,config.nLS);

for j = 1:config.nLS % loop over all loudpspeakers
    disp([j config.nLS]) %display calculation (time) for every LS
    
    i = 1; % set fill-index of imp
    
    imp = zeros(config.N2,config.nLS); % allocate memory temporarily for single impulse responses of bilinear transformed terms
     
    for m = -N21 : N22 % band limitation for loudspeakers
    
        B=zeros(1,abs(m)+1); % allocate memory for denominator of driving function
        A=zeros(1,abs(m)+1); % allocate memory for numerator of driving function
    
    
        for k=0:abs(m) % calculate inner sum of denominator and whole denominator
            B(k+1) = beta1(abs(m),k);
            B(k+1) = B(k+1).* (config.R./config.c)^k ;
        end
        
    B = fliplr(B); % flip vector entries for descending order of denominator
    A(1) = (config.R/config.c)^(k); % calculate numerator (order numerator = order denominator)
    
    
    % stores sos transfer function in a [Lx6] matrix
    [sos,gain] = tf2sos(A,B);
    p = size(sos);
    p = p(1);
    
    %create a new matrix for numerator (and denominator) with size [Lx3]
    num = zeros(p,3); 
    den = num; 
      
        %perform bilinear transformation on all transfer funtions in sos
         for l = 1:p
             [numd,dend] = bilinear(sos(l,1:3),sos(l,4:6),config.fs);
             num(l,:) =  numd; % store achieved numerator
             den(l,:) =  dend; % store achieved denominator
         end
         
    % create a new sos system with bilinear tranformed terms
    sos_bilinear = [num den]; 
   
    % transform to an sos Object
    Hd = dfilt.df2sos(sos_bilinear,gain);
   
    % filter the Hd Object with an impulse of length L
    imp(:,i) = filter(Hd,[1 zeros(1,config.N2-1)]);
    
    % add fourier coefficients and incidence angle (delay) of plane wave
    imp(:,i) = imp(:,i)*exp( 1i*m*(-config.al_pw + alpha_0(j)));
    
    i=i+1; % set index up to get next impulse response
    
    end

% derive number of coloums of imp to get index for adding 
u = size(imp);
p = u(2);

        for q = 1:p % add all calculated impulse responses of filter to get desired impulse response of LS j
             
            imp_resp(:,j)= bsxfun(@plus,imp(:,q),imp_resp(:,j));  
        end

  
end
% get real part of impulses and flip matrix for rigth orientation
% note: there should be no imaginary parts in the impulse responses. 
% Because of the addition of the single impulse responses from the 
% SOS-System the imaginary parts should be eliminated. But MATLAB has
% some numerical problems with this. That's why some impulse responses
% have an imaginary part which is very small...
OUT = flipud(real(imp_resp));

end

