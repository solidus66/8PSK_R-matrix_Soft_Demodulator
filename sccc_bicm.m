clear;
rng(1963);
st1 = 27221; 
st2 = 4831;                  % States for random number generator
frameLength = 1024;
hConEnc1 = comm.ConvolutionalEncoder('TrellisStructure',poly2trellis(3, [7 5],7),'TerminationMethod','Truncated');
hConEnc2 = comm.ConvolutionalEncoder('TrellisStructure',poly2trellis([3 3],[7 0 5;0 7 6],[7 7]),'TerminationMethod','Truncated');

bps = 3;
EbNo = (0:0.2:2);

pskMod = comm.PSKModulator('BitInput',true); % Создание PSK модулятора
hAPPDec1 = comm.APPDecoder(...
    'TrellisStructure',poly2trellis(3, [7 5],7), ...
    'Algorithm','True APP','CodedBitLLROutputPort',true);
hAPPDec2 = comm.APPDecoder(...
    'TrellisStructure',poly2trellis([3 3],[7 0 5;0 7 6],[7 7]), ...
    'Algorithm','True APP','CodedBitLLROutputPort',true);

softerr = comm.ErrorRate;
softerr1 = comm.ErrorRate;
softerr2 = comm.ErrorRate;
softerr3 = comm.ErrorRate;

ber1 = zeros(1,length(EbNo));
ber2 = zeros(1,length(EbNo));
ber3 = zeros(1,length(EbNo));
ber4 = zeros(1,length(EbNo));


for k = 1:length(EbNo)
    
    softerrorStats0 = zeros(1,3);
    softerrorStats1 = zeros(1,3);
    softerrorStats2 = zeros(1,3);
    softerrorStats3 = zeros(1,3);

    rate = 1/2;
    EsNo = EbNo(k) + 10*log10(bps);
    snrdB = EsNo + 10*log10(rate);
    noiseVar = 1./(10.^(snrdB/10));  % Дисперсия шума

    % Цикл для подсчета ошибок
    while softerrorStats3(2) < 3000 && softerrorStats3(3) < 1e6
        % Генерация данных

        data = randi([0 1], frameLength, 1);
        encodedData1 = hConEnc1(data);
        inter1 = randintrlv(encodedData1,st1); % Interleave 1
        encodedData2 = hConEnc2(inter1);
        inter2 = randintrlv(encodedData2,st2); % Interleave 2
        modSignal = pskMod(inter2);
        awgnChan = comm.AWGNChannel('NoiseMethod','Variance','VarianceSource','Property','Variance', noiseVar);
        receivedSignal = awgnChan(modSignal);

        sd1 = zeros(1,3*length(receivedSignal));
        %softReceivedData =  zeros(1,2048);
        softReceivedData = demap8PSK_Rmatrix(receivedSignal, sd1, noiseVar);
        deinter2 = randdeintrlv(softReceivedData,st2); % Deinterleave 2
        [OuterOutU,OuterOutC] = hAPPDec2(zeros(2048,1),deinter2);
        deinter1 = randdeintrlv(OuterOutU,st1); % Deinterleave.
        [InnerOutU,InnerOutC] = hAPPDec1(zeros(1024,1),deinter1);
       
        receivedBits0 = (double(InnerOutU > 0));
        softerrorStats0 = softerr(data,receivedBits0);
        
        % Second iteration
        inter2 = randintrlv(OuterOutC,st2); % Interleave.
        inter1 = randintrlv(InnerOutC,st1); % Interleave.
        softReceivedData = demap8PSK_Rmatrix(receivedSignal, inter2, noiseVar);
        deinter2 = randdeintrlv(softReceivedData,st2); % Deinterleave.
        [OuterOutU,OuterOutC] = hAPPDec2(inter1,deinter2);
        deinter1 = randdeintrlv(OuterOutU,st1); % Deinterleave.
        [InnerOutU,InnerOutC] = hAPPDec1(zeros(1024,1),deinter1);
       
        receivedBits1 = (double(InnerOutU > 0));
        softerrorStats1 = softerr1(data,receivedBits1);
    
        % Third iteration
        inter2 = randintrlv(OuterOutC,st2); % Interleave.
        inter1 = randintrlv(InnerOutC,st1); % Interleave.
        softReceivedData = demap8PSK_Rmatrix(receivedSignal, inter2, noiseVar);
        deinter2 = randdeintrlv(softReceivedData,st2); % Deinterleave.
        [OuterOutU,OuterOutC] = hAPPDec2(inter1,deinter2);
        deinter1 = randdeintrlv(OuterOutU,st1); % Deinterleave.
        [InnerOutU,InnerOutC] = hAPPDec1(zeros(1024,1),deinter1);
       
        receivedBits2 = (double(InnerOutU > 0));
        softerrorStats2 = softerr2(data,receivedBits2);

        % Forth iteration
        inter2 = randintrlv(OuterOutC,st2); % Interleave.
        inter1 = randintrlv(InnerOutC,st1); % Interleave.
        softReceivedData = demap8PSK_Rmatrix(receivedSignal, inter2, noiseVar);
        deinter2 = randdeintrlv(softReceivedData,st2); % Deinterleave.
        [OuterOutU,OuterOutC] = hAPPDec2(inter1,deinter2);
        deinter1 = randdeintrlv(OuterOutU,st1); % Deinterleave.
        [InnerOutU,InnerOutC] = hAPPDec1(zeros(1024,1),deinter1);
       
        receivedBits3 = (double(InnerOutU > 0));
        softerrorStats3 = softerr3(data,receivedBits3);
        
        fprintf('Выполнение: %.2f%%\n', (k / length(EbNo)) * 100);
    end

    ber1(k) = softerrorStats0(1);
    ber2(k) = softerrorStats1(1);
    ber3(k) = softerrorStats2(1);
    ber4(k) = softerrorStats3(1);
    reset(softerr);
    reset(softerr1);
    reset(softerr2);
    reset(softerr3);
end


% Построение графика
figure
semilogy(EbNo,ber1,'-o',EbNo,ber2,"-diamond",EbNo,ber3,"-hexagram",...
    EbNo,ber4,'-+')
grid
xlabel('Eb/N0 (dB)')
ylabel('Bit Error Rate')
legend('1 iteration','2 iterations','3 iterations',...
    '4 iterations')

function LLRs = demap8PSK_Rmatrix(sig, sd, sigma2) %  sd - soft decision
B = [[1,1,0];  % область i
     [1,1,1];  % область ii
     [1,0,1];  % область iii
     [1,0,0];  % область iv
     [0,0,0];  % область v
     [0,0,1];  % область vi
     [0,1,1];  % область vii
     [0,1,0]]; % область viii

S = cat(3, [1,8; 1,3; 2,1], ...  % область i
           [2,8; 2,3; 2,1], ...  % область ii
           [3,5; 2,3; 3,4], ...  % область iii
           [4,5; 2,4; 3,4], ...  % область iv
           [4,5; 7,5; 6,5], ...  % область v
           [4,6; 7,6; 6,5], ...  % область vi
           [1,7; 7,6; 7,8], ...  % область vii
           [1,8; 8,6; 7,8]);     % область viii

LLRs = zeros(1, length(sig)*3);

for k=0:(length(sig) - 1)
    yI = real(sig(k+1));
    yQ = imag(sig(k+1));

    phaseAngle = atan2(yQ, yI);

    region = determineRegion(phaseAngle);

    R = getRMatrix(region);

    % Вычисляем LLR значения 
    LLRs(3*k+1) = (1/sigma2) * (yI * R(1,1) + yQ * R(2,1)) ...
        + B(S(1,1,region),2) * sd(3*k+2) + B(S(1,1,region),3) * sd(3*k+3) ...
        - B(S(1,2,region),2) * sd(3*k+2) - B(S(1,2,region),3) * sd(3*k+3);
    LLRs(3*k+2) = (1/sigma2) * (yI * R(1,2) + yQ * R(2,2))...
        + B(S(2,1,region),1) * sd(3*k+1) + B(S(2,1,region),3) * sd(3*k+3)...
        - B(S(2,2,region),1) * sd(3*k+1) - B(S(2,2,region),3) * sd(3*k+3);
    LLRs(3*k+3) = (1/sigma2) * (yI * R(1,3) + yQ * R(2,3))...
        + B(S(3,1,region),1) * sd(3*k+1) + B(S(3,1,region),2) * sd(3*k+2)...
        - B(S(3,2,region),1) * sd(3*k+1) - B(S(3,2,region),2) * sd(3*k+2);
end

LLRs = reshape(LLRs, [], 1);
end

function region = determineRegion(phaseAngle)

phaseAngle = mod(phaseAngle + pi, 2*pi) - pi;

region_bounds = [-pi, -3*pi/4, -pi/2, -pi/4, 0, pi/4, pi/2, 3*pi/4];

region = find(phaseAngle >= region_bounds, 1, 'last');
if isempty(region)
    region = 1;
end
end

function R = getRMatrix(region)
angles_b0 = [
    -7*pi/8, 7*pi/8;  % область i
    -5*pi/8, 7*pi/8;  % область ii
    -3*pi/8, pi/8;    % область iii
    -pi/8,   pi/8;    % область iv
    -pi/8,   pi/8;    % область v
    -pi/8,   3*pi/8;  % область vi
    -7*pi/8, 5*pi/8;  % область vii
    -7*pi/8, 7*pi/8   % область viii
    ];

phi_1_b0 = angles_b0(region, 1);
phi_0_b0 = angles_b0(region, 2);

cos_diff_b0 = cos(phi_1_b0) - cos(phi_0_b0);
sin_diff_b0 = sin(phi_1_b0) - sin(phi_0_b0);

angles_b1 = [
    -7*pi/8, -3*pi/8; % область i
    -5*pi/8, -3*pi/8; % область ii
    -5*pi/8, -3*pi/8; % область iii
    -5*pi/8, -pi/8;   % область iv
    5*pi/8, pi/8;     % область v
    5*pi/8, 3*pi/8;   % область vi
    5*pi/8, 3*pi/8;   % область vii
    7*pi/8, 3*pi/8;   % область viii
    ];

phi_1_b1 = angles_b1(region, 1);
phi_0_b1 = angles_b1(region, 2);

cos_diff_b1 = cos(phi_1_b1) - cos(phi_0_b1);
sin_diff_b1 = sin(phi_1_b1) - sin(phi_0_b1);

angles_b2 = [
    -5*pi/8, -7*pi/8; % область i
    -5*pi/8, -7*pi/8; % область ii
    -3*pi/8, -pi/8;   % область iii
    -3*pi/8, -pi/8;   % область iv
    3*pi/8,  pi/8;    % область v
    3*pi/8,  pi/8;    % область vi
    5*pi/8,  7*pi/8;  % область vii
    5*pi/8,  7*pi/8;  % область viii
    ];

phi_1_b2 = angles_b2(region, 1);
phi_0_b2 = angles_b2(region, 2);

cos_diff_b2 = cos(phi_1_b2) - cos(phi_0_b2);
sin_diff_b2 = sin(phi_1_b2) - sin(phi_0_b2);

R = [
    cos_diff_b0, cos_diff_b1, cos_diff_b2;
    sin_diff_b0, sin_diff_b1, sin_diff_b2;
    ];
end
