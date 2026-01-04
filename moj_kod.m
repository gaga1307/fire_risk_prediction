%% Broj uzoraka
N = 1400;

%==========================================================================
% 1. Generisanje sintetičkih ulaza za predvidjanje rizika od šumskih požara
%==========================================================================

Temperatura = randi([0 50], N, 1);      % °C
Vlaznost    = randi([0 100], N, 1);      % %
Vetar       = randi([0 20], N, 1);       % m/s
NagibTerena = randi([0 60], N, 1);       % stepeni

inputs = [Temperatura, Vlaznost, Vetar, NagibTerena];

%==========================================================================
% 2. Min-max skaliranje ulaza na [0,1]
%==========================================================================

min_vals = [0  0   0   0];    % [min Temp, min Vlaz, min Vetar, min Nagib]
max_vals = [50 100 20  60];   % [max Temp, max Vlaz, max Vetar, max Nagib]

inputs_scaled = (inputs - min_vals) ./ (max_vals - min_vals);

T = inputs_scaled(:,1);   % normalizovana temperatura
H = inputs_scaled(:,2);   % normalizovana vlažnost
W = inputs_scaled(:,3);   % normalizovana brzina vetra
G = inputs_scaled(:,4);   % normalizovan nagib terena

%==========================================================================
% 3. Generisanje izlaza – rizika (kontinualna vrednost 0–1) simulacijom
%==========================================================================

% - rizik raste sa temperaturom, vetrom i nagibom
% - rizik opada sa vlažnošću
% Uzimamo u obzir i nelinearne odnose ulaza:
% Kad su i temperatura i vetar veliki - rizik još više skače
% Kada su visoka temperatura i veliki nagib - požar se lakše širi uzbrdo i
% rizik je veci
% Ako postoji i vlažnost i veliki nagib - vlažnost malo umanjuje efekat
% nagiba tj. rizik se smanjuje

output = 0.40*T - 0.30*H + 0.35*W + 0.35*G ...
         + 0.20*T.*W + 0.15*T.*G - 0.10*H.*G;

% dodavanje malo šuma kako bi podaci bili realniji
output = output + 0.03*randn(N,1);

% skaliranje izlaza na [0,1]
output = max(0, min(1, output));

%==========================================================================
% 4. Matrica podataka za ANFIS
%==========================================================================

data = [inputs_scaled, output];
numInputs = size(inputs_scaled, 2);

%==========================================================================
% 5. Generisanje početnog FIS-a pomoću subclusteringa
%==========================================================================
clusterInfluenceRange = 0.7;  %optimalna vrednost raspona uticaja dobijena je kroz vise pokusaja
fis = genfis2(inputs_scaled, output, clusterInfluenceRange);

%==========================================================================
% 6. Podela podataka na trening/checking
%==========================================================================

idx = randperm(N);
nTrain = round(0.8 * N);

trainData = data(idx(1:nTrain), :);
checkData = data(idx(nTrain+1:end), :);

%==========================================================================
% 7. ANFIS treniranje za dobijanje optimalnih vrednosti parametra sistema
%==========================================================================

numEpochs = 70;

[trainedFis, trainError, ~, checkFis, checkError] = ...
    anfis(trainData, fis, numEpochs, [], checkData);

%==========================================================================
% 8. Čuvanje modela
%==========================================================================

writeFIS(trainedFis, 'AnfisModel_Pozari');
disp('Obučeni ANFIS model je sačuvan kao AnfisModel_Pozari.fis');

%==========================================================================
% 9. Graf greške
%==========================================================================

figure;
plot(1:numEpochs, trainError, 'b', 'LineWidth', 1.3); hold on;
plot(1:numEpochs, checkError, 'r--', 'LineWidth', 1.3);
xlabel('Epohе');
ylabel('RMSE');
title('Greška ANFIS trening i checking – rizik od šumskih požara');
legend('Training', 'Checking');

%==========================================================================
% 10. Testiranje dobijenog modela na nevidjenim podacima
%==========================================================================

predictedOutput = evalfis(checkData(:, 1:numInputs), trainedFis);
actualOutput    = checkData(:, end);

figure;
plot(actualOutput, 'bo', 'DisplayName', 'Stvarne vrednosti'); hold on;
plot(predictedOutput, 'r*', 'DisplayName', 'Predviđene vrednosti');
xlabel('Uzorak');
ylabel('Rizik od požara');
title('Stvarni vs predviđeni rizik – ANFIS');
legend;
grid on;
