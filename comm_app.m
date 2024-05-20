clear;
% Параметры
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