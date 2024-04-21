%% Тест demap8PSK_Rmatrix.m
angles = (-7:2:7) * pi/8;

noise_levels = [1e-12, 0.05, 0.2];

for sigma2 = noise_levels
    fprintf('Тест при sigma2 = %f\n', sigma2);
    for i = 1:length(angles)
        % идеальные координаты точки
        yI = cos(angles(i));
        yQ = sin(angles(i));
        
        % добавление шума
        yI_noisy = yI + sigma2 * randn();
        yQ_noisy = yQ + sigma2 * randn();
        
        % вычисление LLR
        LLRs = demap8PSK_Rmatrix(yI_noisy, yQ_noisy, sigma2);
        
        fprintf('Угол: %5.2f, LLR: [%6.2f, %6.2f, %6.2f]\n', angles(i), LLRs);
    end
    fprintf('\n');
end
fprintf('__________\n')
%% Тест 2
% точки созвездия 8PSK для тестирования
angles = (-7:2:7) * pi/8; % От -7pi/8 до 7pi/8 с шагом pi/4
sigma2 = 0.1;

% проходим по всем тестовым точкам
for i = 1:length(angles)
    yI = cos(angles(i));
    yQ = sin(angles(i));
    
    LLRs = demap8PSK_Rmatrix(yI, yQ, sigma2);

    fprintf('Тестовый угол: %5.2f, LLR: [%6.2f, %6.2f, %6.2f]\n', angles(i), LLRs);
end
fprintf('__________\n')
%% Запуск getRMatrix.m
num_regions = 8; % общее количество областей
for region = 1:num_regions
    disp(['R-матрица для области ', num2str(region), ':']);
    disp(getRMatrix(region));
end
fprintf('__________\n')
%% Проверка determineRegion.m
test_angles = [-pi, -3*pi/4, -pi/2, -pi/4, 0, pi/4, pi/2, 3*pi/4, pi, -7*pi/8];
expected_regions = [1, 2, 3, 4, 5, 6, 7, 8, 1, 1];

for i = 1:length(test_angles)
    calculated_region = determineRegion(test_angles(i));
    fprintf('Угол: %5.2f, Ожидаемая область: %d, Вычисленная область: %d\n', ...
            test_angles(i), expected_regions(i), calculated_region);
end
fprintf('__________\n')