clear;
% параметры
% noiseVar = 2e-1;
noiseVar = (0.025:0.025:0.5); % Диапазон значений дисперсии шума (σ²)
frameLength = 300;

% Создание объектов
convEncoder = comm.ConvolutionalEncoder('TrellisStructure',poly2trellis(7,[171 133]),'TerminationMethod','Truncated');
pskMod = comm.PSKModulator('BitInput',true,'PhaseOffset',0);
appDecoder1 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false);
appDecoder2 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false);

% Инициализация объектов для оценки ошибок
errRate = comm.ErrorRate;
errRateSimp = comm.ErrorRate;

ber1 = zeros(1,length(noiseVar)); % Вектор для хранения BER PSKDemodulator
ber2 = zeros(1,length(noiseVar)); % Вектор для хранения BER Simp8PSK (demap8PSK_Rmatrix)
EbNo = zeros(1,length(noiseVar)); % Вектор для хранения значений Eb/No

for k = 1:length(noiseVar)
    errorStats = zeros(1,3);
    errorStatsSimp = zeros(1,3);

    % Расчет Eb/No
    EbNo(k) = 1 / (2 * noiseVar(k));

    while errorStats(2) < 1000 && errorStats(3) < 1e7
        % Генерация данных
        data = randi([0 1], frameLength, 1);
        encodedData = convEncoder(data);
        modSignal = pskMod(encodedData);
        awgnChan = comm.AWGNChannel('NoiseMethod','Variance', 'Variance',noiseVar(k));
        receivedSignal = awgnChan(modSignal);

        % Демодуляция с использованием PSKDemodulator
        pskDemod = comm.PSKDemodulator('BitOutput',true,'PhaseOffset',pi/8, 'DecisionMethod','Approximate log-likelihood ratio', 'Variance',noiseVar(k));
        demodSignal = pskDemod(receivedSignal);
        receivedSoftBits = appDecoder1(zeros(frameLength, 1), -demodSignal);
        receivedBits = double(receivedSoftBits > 0);
        errorStats = errRate(data, receivedBits);

        % Демодуляция с использованием demap8PSK_Rmatrix
        demodSignal8PSK = demap8PSK_Rmatrix(receivedSignal, noiseVar(k));
        receivedSoftBits8PSK = appDecoder2(zeros(frameLength, 1), demodSignal8PSK);
        receivedBits8PSK = double(receivedSoftBits8PSK > 0);
        errorStatsSimp = errRateSimp(data, receivedBits8PSK);
    end
    % Сохранение данных BER и сброс объекта для оценки ошибок
    ber1(k) = errorStats(1);
    ber2(k) = errorStatsSimp(1);
    reset(errRate);
    reset(errRateSimp);
end

figure
semilogy(10*log10(EbNo),ber1,'-o',10*log10(EbNo),ber2,"-diamond") % Построение графика BER в зависимости от Eb/No (в дБ)
grid
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
legend('PSKDemodulator','demap8PSK_Rmatrix')

function LLRs = demap8PSK_Rmatrix(sig, sigma2) % sig - это комплексный вектор символов
% инициализация массива LLR значений
LLRs = zeros(1, length(sig)*3);

% проходим по каждому символу и вычисляем LLR значения
for k=0:(length(sig) - 1)
    yI = real(sig(k+1));
    yQ = imag(sig(k+1));

    % вычисляем фазовый угол принятого символа
    phaseAngle = atan2(yQ, yI);

    % определяем область на основе фазового угла
    region = determineRegion(phaseAngle);

    % получаем R-матрицу для определенной области
    R = getRMatrix(region);

    % вычисляем LLR значения для текущего символа
    LLRs(3*k+1) = yI * (1/sigma2) * R(1,1) + yQ * (1/sigma2) * R(2,1);
    LLRs(3*k+2) = yI * (1/sigma2) * R(1,2) + yQ * (1/sigma2) * R(2,2);
    LLRs(3*k+3) = yI * (1/sigma2) * R(1,3) + yQ * (1/sigma2) * R(2,3);
end

LLRs = reshape(LLRs, [], 1);
end

function region = determineRegion(phaseAngle)
% нормализация угла фазы в диапазон [-pi, pi)
phaseAngle = mod(phaseAngle + pi, 2*pi) - pi;

% определение границ для всех восьми областей
region_bounds = [-pi, -3*pi/4, -pi/2, -pi/4, 0, pi/4, pi/2, 3*pi/4];

% определение области фазового угла
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
