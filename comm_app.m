clear;
% Параметры
bps = 3;  % Количество бит на символ для 8PSK
EbN0_dB = (0:0.5:10);  % Значения Eb/N0 в дБ
frameLength = 300;  % Длина кадра

% Создание объектов
convEncoder = comm.ConvolutionalEncoder('TrellisStructure',poly2trellis(7,[171 133]),'TerminationMethod','Truncated'); % Создание свёрточного кодера
pskMod = comm.PSKModulator('BitInput',true,'PhaseOffset',0, 'ModulationOrder', 8); % Создание PSK модулятора
appDecoder1 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false); % Создание декодера APP
appDecoder2 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false); % Создание второго декодера APP

% Инициализация объектов для подсчета ошибок
errRate = comm.ErrorRate; % Объект для подсчета ошибок
errRateSimp = comm.ErrorRate; % Второй объект для подсчета ошибок

% Предварительное выделение массивов BER
ber1 = zeros(1,length(EbN0_dB));   % Вектор для хранения BER PSKDemodulator
ber2 = zeros(1,length(EbN0_dB));   % Вектор для хранения BER Simp8PSK (demap8PSK_Rmatrix)

for k_idx = 1:length(EbN0_dB)
    rate = 1/2;
    EsNo = EbN0_dB(k_idx) + 10*log10(bps);  % Преобразование Eb/N0 в Es/N0
    snrdB = EsNo + 10*log10(rate);  % Отношение сигнал/шум в дБ
    noiseVar = 1./(10.^(snrdB/10));  % Дисперсия шума

    % Инициализация статистики ошибок
    errorStats = zeros(1,3);  % Статистика ошибок для PSKDemodulator
    errorStatsSimp = zeros(1,3);  % Статистика ошибок для Simp8PSK (demap8PSK_Rmatrix)

    % Цикл для подсчета ошибок
    while errorStats(2) < 2000 && errorStats(3) < 1e7
        % Генерация данных
        data = randi([0 1], frameLength, 1);
        encodedData = convEncoder(data);
        modSignal = pskMod(encodedData);
        awgnChan = comm.AWGNChannel('NoiseMethod','Variance', 'Variance',noiseVar);
        receivedSignal = awgnChan(modSignal);

        % Демодуляция с использованием PSKDemodulator
        pskDemod = comm.PSKDemodulator('BitOutput',true,'PhaseOffset',pi/8, 'DecisionMethod','Approximate log-likelihood ratio', 'Variance',noiseVar);
        demodSignal = pskDemod(receivedSignal);
        receivedSoftBits = appDecoder1(zeros(frameLength, 1), -demodSignal);
        receivedBits = double(receivedSoftBits > 0);
        errorStats = errRate(data, receivedBits);

        % Демодуляция с использованием demap8PSK_Rmatrix
        demodSignal8PSK = demap8PSK_Rmatrix(receivedSignal, noiseVar);
        receivedSoftBits8PSK = appDecoder2(zeros(frameLength, 1), demodSignal8PSK);
        receivedBits8PSK = double(receivedSoftBits8PSK > 0);
        errorStatsSimp = errRateSimp(data, receivedBits8PSK);
    end

    % Сохранение данных BER и сброс объектов подсчета ошибок
    ber1(k_idx) = errorStats(1);  % Сохранение BER для PSKDemodulator
    ber2(k_idx) = errorStatsSimp(1);  % Сохранение BER для Simp8PSK (demap8PSK_Rmatrix)
    reset(errRate);  % Сброс объекта подсчета ошибок
    reset(errRateSimp);  % Сброс второго объекта подсчета ошибок

    fprintf('Выполнение: %.2f%%\n', (k_idx / length(EbN0_dB)) * 100);
end

% Построение графика BER
figure
semilogy(EbN0_dB,ber1,'-o',EbN0_dB,ber2,"-diamond");
grid;
xlabel('E_b/N_0 (dB)');  % Подпись оси X
ylabel('Bit Error Rate');  % Подпись оси Y
legend('PSKDemodulator','demap8PSK_Rmatrix');