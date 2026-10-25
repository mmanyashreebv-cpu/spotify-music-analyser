

clc;
clear;
close all;

% Select Spotify CSV file
[file, path] = uigetfile('*.csv', 'Select Spotify Dataset');

if isequal(file, 0)
    disp('No file selected');
    return;
end

data = readtable(fullfile(path, file));

% Check required columns
requiredColumns = {'track_name', 'artists', 'popularity'};

if ~all(ismember(requiredColumns, data.Properties.VariableNames))
    disp('Required columns not found.');
    disp(data.Properties.VariableNames);
    return;
end

% Sort by popularity
data = sortrows(data, 'popularity', 'descend');

% Select top 10 songs
top10 = data(1:min(10, height(data)), :);

% Display results
disp('Top 10 Popular Songs:');
disp(top10(:, requiredColumns));

% Create bar graph
figure;
bar(top10.popularity);
title('Top 10 Popular Spotify Songs');
xlabel('Song Rank');
ylabel('Popularity Score');
xticks(1:height(top10));
grid on;


% Audio Feature Analysis

% Check required audio feature columns
features = {'danceability', 'energy', 'tempo'};

if all(ismember(features, data.Properties.VariableNames))

    % Calculate average values
    avgDanceability = mean(data.danceability, 'omitnan');
    avgEnergy = mean(data.energy, 'omitnan');
    avgTempo = mean(data.tempo, 'omitnan');

    % Display results
    fprintf('\n--- Audio Feature Analysis ---\n');
    fprintf('Average Danceability: %.2f\n', avgDanceability);
    fprintf('Average Energy: %.2f\n', avgEnergy);
    fprintf('Average Tempo: %.2f BPM\n', avgTempo);

    % Create bar chart
    figure;
    averages = [avgDanceability, avgEnergy];
    bar(averages);

    xticklabels({'Danceability', 'Energy'});
    ylabel('Average Score');
    title('Average Danceability and Energy');
    ylim([0 1]);
    grid on;

    % Create tempo histogram
    figure;
    histogram(data.tempo);
    title('Distribution of Song Tempos');
    xlabel('Tempo (BPM)');
    ylabel('Number of Songs');
    grid on;

else
    disp('One or more audio feature columns are missing.');
    disp(data.Properties.VariableNames);
end


% Step 7: Genre Analysis

% Check whether genre column exists
if ismember('track_genre', data.Properties.VariableNames)

    % Count songs in each genre
    [genres, ~, idx] = unique(data.track_genre);
    genreCounts = accumarray(idx, 1);

    % Sort genres by number of songs
    [sortedCounts, order] = sort(genreCounts, 'descend');

    % Select top 10 genres
    n = min(10, length(sortedCounts));
    topGenres = genres(order(1:n));
    topCounts = sortedCounts(1:n);

    % Display results
    disp('Top 10 Genres by Number of Songs:');
    disp(table(topGenres, topCounts, ...
        'VariableNames', {'Genre', 'NumberOfSongs'}));

    % Plot genre chart
    figure;
    bar(topCounts);
    xticks(1:n);
    xticklabels(topGenres);
    xtickangle(45);
    xlabel('Genre');
    ylabel('Number of Songs');
    title('Top 10 Music Genres in Spotify Dataset');
    grid on;

else
    disp('Genre column not found.');
    disp(data.Properties.VariableNames);
end


% Step 8: Song Search Feature

songName = input('Enter a song name to search: ', 's');

% Find matching songs (case-insensitive)
songNames = string(data.track_name);
match = strcmpi(strtrim(songNames), strtrim(songName));

% Check if song exists
if any(match)

    results = data(match, :);

    disp('Song found!');
    disp(results(:, {'track_name', 'artists', ...
        'popularity', 'danceability', 'energy', 'tempo'}));

else
    disp('Song not found in the dataset.');
end
