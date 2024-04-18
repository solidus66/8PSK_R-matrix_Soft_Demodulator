% Инициализация параметров системы
noiseVar = 2e-1;
frameLength = 300;
convEncoder = comm.ConvolutionalEncoder('TerminationMethod', 'Truncated');
pskMod = comm.PSKModulator('BitInput', true, 'PhaseOffset', 0);
awgnChan = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar);

appDecoder = comm.APPDecoder('TrellisStructure', poly2trellis(7, [171 133]), ...
    'Algorithm', 'True APP', 'CodedBitLLROutputPort', false);
errRate = comm.ErrorRate;

% Параметры для визуализации
EbNo_values = 0:1:10; % Диапазон значений Eb/No
BER = zeros(1, length(EbNo_values)); % Массив для хранения BER

% Цикл для симуляции и визуализации
for n = 1:length(EbNo_values)
    % Обновление шумового отклонения в соответствии с Eb/No
    noiseVar = 10^(-EbNo_values(n)/10);
    awgnChan.Variance = noiseVar;
    
    % Сброс состояния объекта подсчета ошибок
    errRate.reset();
    
    for counter = 1:5
        data = randi([0 1], frameLength, 1);
        encodedData = convEncoder(data);
        modSignal = pskMod(encodedData);
        receivedSignal = awgnChan(modSignal);
        
        % Используем пользовательскую функцию demap8PSK_Rmatrix для LLR
        LLRs = demap8PSK_Rmatrix(receivedSignal, noiseVar); 
        
        % Декодирование сигнала
        receivedSoftBits = appDecoder(zeros(frameLength, 1), -LLRs(:)); % Обратите внимание на полярность
        receivedBits = double(receivedSoftBits > 0);
        
        % Подсчет ошибок
        errorStats = errRate(data, receivedBits);
    end
    
    % Запись результатов BER для текущего Eb/No
    BER(n) = errorStats(1);
end

% Вывод информации о коэффициенте ошибок
fprintf('Error rate = %f\nNumber of errors = %d\n', errorStats(1), errorStats(2));

% Визуализация BER в зависимости от Eb/No
figure;
semilogy(EbNo_values, BER, '-o');
grid on;
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. Eb/No for 8PSK with Convolutional Coding');
