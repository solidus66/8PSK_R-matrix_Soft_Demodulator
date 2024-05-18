% Параметры
noiseVar = 2e-1;
frameLength = 300;

% Создание объектов
convEncoder = comm.ConvolutionalEncoder('TerminationMethod','Truncated');
pskMod = comm.PSKModulator('BitInput',true,'PhaseOffset',0);
awgnChan = comm.AWGNChannel('NoiseMethod','Variance', 'Variance',noiseVar);
appDecoder = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false);
pskDemod = comm.PSKDemodulator('BitOutput',true,'PhaseOffset',0, 'DecisionMethod','Approximate log-likelihood ratio', 'Variance',noiseVar);

% Новый демодулятор для 8PSK
pskDemod8PSK = @(receivedSignal) demap8PSK_Rmatrix(receivedSignal, noiseVar);

% Инициализация объекта для подсчета ошибок
errRate = comm.ErrorRate;

for counter = 1:5
    % Генерация данных
    data = randi([0 1],frameLength,1);
    encodedData = convEncoder(data);
    modSignal = pskMod(encodedData);
    receivedSignal = awgnChan(modSignal);
    
    % Демодуляция с использованием существующего демодулятора
    demodSignal = pskDemod(receivedSignal);
    receivedSoftBits = appDecoder(zeros(frameLength,1),-demodSignal);
    receivedBits = double(receivedSoftBits > 0);
    errorStats = errRate(data,receivedBits);
    
    % Демодуляция с использованием нового демодулятора
    demodSignal8PSK = pskDemod8PSK(receivedSignal);
    receivedSoftBits8PSK = appDecoder(zeros(frameLength,1),-demodSignal8PSK);
    receivedBits8PSK = double(receivedSoftBits8PSK > 0);
    errorStats8PSK = errRate(data,receivedBits8PSK);
end

% Вывод результатов
fprintf('Error rate (existing) = %f\nNumber of errors (existing) = %d\n', errorStats(1), errorStats(2));
fprintf('Error rate (8PSK) = %f\nNumber of errors (8PSK) = %d\n', errorStats8PSK(1), errorStats8PSK(2));
fprintf('__________\n')