% %% Запуск demap8PSK_Rmatrix.m
% y = [1+1i, -1-1i, 1-1i, -1+1i]; % примерный вектор комплексных чисел
% sigma2 = 0.1; % примерное значение дисперсии шума
% 
% llr = demap8PSK_Rmatrix(y, sigma2);
% 
% disp('Мягкие решения (LLR):');
% disp(llr);


% Параметры сигнала
M = 8; % 8PSK, так что M = 8
phi = linspace(0, 2*pi, M+1); % Генерация M равномерно распределенных фаз от 0 до 2*pi
phi(end) = []; % Удалить последнюю точку, так как она совпадает с первой

% Создание комплексных точек сигнала
s = exp(1i * phi); % Идеальные точки созвездия

% Добавление шума
sigma = 1; % Уровень шума
noise = sigma * (randn(size(s)) + 1i * randn(size(s))); % Гауссовский шум
y = s + noise; % Сигнал с шумом

% Сохранение тестовых данных
save('test_data.mat', 'y', 'sigma');
% Загрузка тестовых данных
load('test_data.mat');

% Вызов функции демодуляции
LLRs = demap8PSK_Rmatrix(y, sigma);

% Вывод результатов
disp('Рассчитанные LLR:');
disp(LLRs);


%% Запуск getRMatrix.m
% % region = input('Укажите область (1-8): ');
% % R_matrix_area = getRMatrix(region);
% % R_matrix_area = getRMatrix(1);
% % disp('R-матрица для указанной области');
% disp('R-матрица')
% disp(getRMatrix(1));
% disp(getRMatrix(2));
% disp(getRMatrix(3));
% disp(getRMatrix(4));
% disp(getRMatrix(5));
% disp(getRMatrix(6));
% disp(getRMatrix(7));
% disp(getRMatrix(8));