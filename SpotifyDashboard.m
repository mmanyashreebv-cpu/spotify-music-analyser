function SpotifyDashboard
% SPOTIFYDASHBOARD - Spotify-inspired music analytics dashboard.
% Save this file as SpotifyDashboard.m and run: SpotifyDashboard

clc;
close all;

%% Load dataset
[file, folder] = uigetfile({'*.csv','CSV files (*.csv)'}, ...
    'Select your Spotify tracks CSV file');

if isequal(file, 0)
    disp('Dataset selection cancelled.');
    return;
end

data = readtable(fullfile(folder, file));

% Required dataset columns
required = {'track_name','artists','popularity', ...
    'danceability','energy','tempo','track_genre'};

missing = required(~ismember(required, data.Properties.VariableNames));
if ~isempty(missing)
    error('Dataset is missing required column(s): %s', strjoin(missing, ', '));
end
if height(data) == 0
    error('The selected CSV contains no tracks.');
end

% Normalize text columns
data.track_name = string(data.track_name);
data.artists = string(data.artists);
data.track_genre = string(data.track_genre);

% Convert numeric columns if they were imported as text
numericColumns = {'popularity','danceability','energy','tempo'};
for c = 1:numel(numericColumns)
    col = numericColumns{c};
    if ~isnumeric(data.(col))
        data.(col) = str2double(string(data.(col)));
    end
end

% Drop rows without a song name
validNames = ~ismissing(data.track_name) & strlength(strtrim(data.track_name)) > 0;
data = data(validNames,:);
if height(data) == 0
    error('No rows with valid track names were found.');
end

%% Theme
bg = [0.055 0.065 0.060];
sidebarBg = [0.025 0.035 0.030];
panelBg = [0.105 0.125 0.115];
cardBg = [0.12 0.145 0.13];
green = [0.12 0.84 0.38];
greenDark = [0.07 0.48 0.25];
white = [0.96 0.98 0.96];
muted = [0.68 0.73 0.69];
gridColor = [0.25 0.30 0.27];

%% Main window
fig = uifigure('Name','Spotify Music Analyser', ...
    'Position',[70 45 1450 880], ...
    'Color',bg);
fig.Resize = 'on';

%% Sidebar
sidebar = uipanel(fig,'Position',[1 1 210 880], ...
    'BackgroundColor',sidebarBg,'BorderType','none');

uilabel(sidebar,'Text','●  SPOTIFY', ...
    'Position',[22 805 175 38],'FontSize',22, ...
    'FontWeight','bold','FontColor',green);

uilabel(sidebar,'Text','MUSIC ANALYSER', ...
    'Position',[24 780 165 22],'FontSize',11, ...
    'FontWeight','bold','FontColor',muted);

uilabel(sidebar,'Text','YOUR WORKSPACE', ...
    'Position',[22 720 165 20],'FontSize',9, ...
    'FontWeight','bold','FontColor',[0.48 0.55 0.50]);

btnOverview = uibutton(sidebar,'push','Text','Overview', ...
    'Position',[14 672 180 38],'BackgroundColor',greenDark, ...
    'FontColor',white,'FontWeight','bold','HorizontalAlignment','left', ...
    'ButtonPushedFcn',@showOverview);

btnExplore = uibutton(sidebar,'push','Text','Explore Music', ...
    'Position',[14 625 180 38],'BackgroundColor',sidebarBg, ...
    'FontColor',white,'HorizontalAlignment','left', ...
    'ButtonPushedFcn',@showExplore);

btnInsights = uibutton(sidebar,'push','Text','Discover Trends', ...
    'Position',[14 578 180 38],'BackgroundColor',sidebarBg, ...
    'FontColor',white,'HorizontalAlignment','left', ...
    'ButtonPushedFcn',@showInsights);

uilabel(sidebar,'Text','DATASET', ...
    'Position',[22 510 165 20],'FontSize',9, ...
    'FontWeight','bold','FontColor',[0.48 0.55 0.50]);

datasetLabel = uilabel(sidebar,'Text',sprintf('%s tracks loaded', ...
    string(height(data))), ...
    'Position',[22 475 170 30],'FontSize',11,'FontColor',muted);

uilabel(sidebar,'Text','Tip: search by song title or artist name.', ...
    'Position',[22 85 165 65],'FontSize',10,'FontColor',muted, ...
    'WordWrap','on');

%% Main header
uilabel(fig,'Text','Music Dashboard', ...
    'Position',[240 805 520 44],'FontSize',27, ...
    'FontWeight','bold','FontColor',white);

uilabel(fig,'Text','Your music library, visualized.', ...
    'Position',[243 778 500 24],'FontSize',13,'FontColor',muted);

%% Summary cards
cardW = 255;
cardY = 680;
cardH = 76;
cardX = [240 510 780 1050];

makeCard(cardX(1),cardY,cardW,cardH,'TOTAL TRACKS',sprintf('%s', ...
    string(height(data))));
makeCard(cardX(2),cardY,cardW,cardH,'AVG POPULARITY', ...
    sprintf('%.1f / 100',mean(data.popularity,'omitnan')));
makeCard(cardX(3),cardY,cardW,cardH,'AVG DANCEABILITY', ...
    sprintf('%.2f',mean(data.danceability,'omitnan')));
makeCard(cardX(4),cardY,cardW,cardH,'AVG ENERGY', ...
    sprintf('%.2f',mean(data.energy,'omitnan')));

%% Charts
axPopular = uiaxes(fig,'Position',[240 390 555 250]);
styleAxes(axPopular);
title(axPopular,'Top 10 Popular Songs','Color',white,'FontWeight','bold');
xlabel(axPopular,'Popularity'); ylabel(axPopular,'');

axFeatures = uiaxes(fig,'Position',[815 390 535 250]);
styleAxes(axFeatures);
title(axFeatures,'Audio Feature Averages','Color',white,'FontWeight','bold');
ylabel(axFeatures,'Average score');

axGenres = uiaxes(fig,'Position',[240 105 555 235]);
styleAxes(axGenres);
title(axGenres,'Top 10 Genres','Color',white,'FontWeight','bold');
xlabel(axGenres,'Number of tracks'); ylabel(axGenres,'');

%% Insights panel
insightPanel = uipanel(fig,'Title','MUSIC INSIGHTS', ...
    'Position',[815 105 535 235],'BackgroundColor',panelBg, ...
    'ForegroundColor',white,'FontSize',12);

insightText = uitextarea(insightPanel,'Position',[15 15 505 180], ...
    'Editable','off','FontSize',12,'BackgroundColor',panelBg, ...
    'FontColor',white,'Value',{'Loading insights...'});

%% Search panel across bottom of workspace
searchPanel = uipanel(fig,'Title','EXPLORE YOUR TRACKS', ...
    'Position',[240 15 1110 75],'BackgroundColor',panelBg, ...
    'ForegroundColor',white,'FontSize',11);

uilabel(searchPanel,'Text','Song or artist', ...
    'Position',[12 25 100 22],'FontColor',muted);

searchBox = uieditfield(searchPanel,'text', ...
    'Position',[110 20 300 32], ...
    'Placeholder','Type a song title or artist...');

uilabel(searchPanel,'Text','Genre', ...
    'Position',[430 25 45 22],'FontColor',muted);

genreValues = unique(data.track_genre);
genreValues = genreValues(~ismissing(genreValues) & strlength(genreValues)>0);
genreValues = sort(genreValues);
genreItems = [{'All genres'}; cellstr(genreValues)];

genreDropdown = uidropdown(searchPanel,'Items',genreItems, ...
    'Value','All genres','Position',[475 20 190 32]);

searchButton = uibutton(searchPanel,'push','Text','Search', ...
    'Position',[685 20 100 32],'BackgroundColor',green, ...
    'FontColor',[0.03 0.04 0.03],'FontWeight','bold', ...
    'ButtonPushedFcn',@searchTracks);

resetButton = uibutton(searchPanel,'push','Text','Reset', ...
    'Position',[795 20 85 32],'BackgroundColor',cardBg, ...
    'FontColor',white,'ButtonPushedFcn',@resetDashboard);

statusLabel = uilabel(searchPanel,'Text','Ready', ...
    'Position',[895 20 190 32],'FontSize',10,'FontColor',muted);

%% Initial content
updateDashboard(data);
showOverview();

%% Nested helper functions
    function styleAxes(ax)
        ax.Color = panelBg;
        ax.XColor = white;
        ax.YColor = white;
        ax.GridColor = gridColor;
        ax.FontSize = 9;
        ax.Box = 'off';
        grid(ax,'on');
    end

    function makeCard(x,y,w,h,heading,value)
        p = uipanel(fig,'Position',[x y w h], ...
            'BackgroundColor',cardBg,'BorderType','line');
        uilabel(p,'Text',heading,'Position',[14 43 w-28 18], ...
            'FontSize',9,'FontWeight','bold','FontColor',muted);
        uilabel(p,'Text',value,'Position',[14 10 w-28 30], ...
            'FontSize',20,'FontWeight','bold','FontColor',white);
    end

    function updateDashboard(currentData)
        % Popularity chart: horizontal bars keep song titles readable.
        cla(axPopular);
        sorted = sortrows(currentData,'popularity','descend');
        n = min(10,height(sorted));
        if n > 0
            names = sorted.track_name(1:n);
            names = replace(names,newline,' ');
            barh(axPopular,1:n,flipud(sorted.popularity(1:n)), ...
                'FaceColor',green,'EdgeColor','none');
            axPopular.YTick = 1:n;
            axPopular.YTickLabel = cellstr(flipud(names));
            axPopular.YDir = 'reverse';
            axPopular.XLim = [0 100];
        end
        title(axPopular,'Top 10 Popular Songs','Color',white,'FontWeight','bold');
        xlabel(axPopular,'Popularity');
        axPopular.YLabel.String = '';

        % Feature averages
        cla(axFeatures);
        featureMeans = [mean(currentData.danceability,'omitnan'), ...
            mean(currentData.energy,'omitnan'), ...
            mean(currentData.tempo,'omitnan')];
        % Tempo uses a separate scale, so chart only normalized features.
        bar(axFeatures,1:2,featureMeans(1:2), ...
            'FaceColor',green,'EdgeColor','none');
        axFeatures.XTick = [1 2];
        axFeatures.XTickLabel = {'Danceability','Energy'};
        axFeatures.YLim = [0 1];
        title(axFeatures,'Audio Feature Averages','Color',white,'FontWeight','bold');
        ylabel(axFeatures,'Average score');

        % Genre distribution
        cla(axGenres);
        genres = currentData.track_genre;
        genres = genres(~ismissing(genres) & strlength(genres)>0);
        if ~isempty(genres)
            [uniqueGenres,~,idx] = unique(genres);
            counts = accumarray(idx,1);
            [counts,order] = sort(counts,'descend');
            uniqueGenres = uniqueGenres(order);
            g = min(10,numel(uniqueGenres));
            barh(axGenres,1:g,flipud(counts(1:g)), ...
                'FaceColor',green,'EdgeColor','none');
            axGenres.YTick = 1:g;
            axGenres.YTickLabel = cellstr(flipud(uniqueGenres(1:g)));
            axGenres.YDir = 'reverse';
        end
        title(axGenres,'Top 10 Genres','Color',white,'FontWeight','bold');
        xlabel(axGenres,'Number of tracks');
        axGenres.YLabel.String = '';

        updateInsights(currentData);
        drawnow;
    end

    function updateInsights(currentData)
        if isempty(currentData)
            insightText.Value = {'No tracks available for these filters.'};
            return;
        end
        [~,popIdx] = max(currentData.popularity);
        [~,energyIdx] = max(currentData.energy);
        [~,danceIdx] = max(currentData.danceability);
        validGenres = currentData.track_genre(~ismissing(currentData.track_genre) & ...
            strlength(currentData.track_genre)>0);
        if isempty(validGenres)
            commonGenre = "Unknown";
        else
            [gNames,~,gIdx] = unique(validGenres);
            gCounts = accumarray(gIdx,1);
            [~,gi] = max(gCounts);
            commonGenre = gNames(gi);
        end
        lines = {
            sprintf('Tracks in current view: %d',height(currentData))
            sprintf('Highest popularity: %s — %g/100', ...
                currentData.track_name(popIdx),currentData.popularity(popIdx))
            sprintf('Highest energy: %s (%.2f)', ...
                currentData.track_name(energyIdx),currentData.energy(energyIdx))
            sprintf('Most danceable: %s (%.2f)', ...
                currentData.track_name(danceIdx),currentData.danceability(danceIdx))
            sprintf('Most common genre: %s',commonGenre)
            sprintf('Average tempo: %.1f BPM',mean(currentData.tempo,'omitnan'))
            };
        insightText.Value = lines;
    end

    function searchTracks(~,~)
        query = strtrim(string(searchBox.Value));
        chosenGenre = string(genreDropdown.Value);
        currentData = data;

        if chosenGenre ~= "All genres"
            currentData = currentData(currentData.track_genre == chosenGenre,:);
        end

        if strlength(query) > 0
            match = contains(currentData.track_name,query,'IgnoreCase',true) | ...
                contains(currentData.artists,query,'IgnoreCase',true);
            currentData = currentData(match,:);
        end

        if isempty(currentData)
            statusLabel.Text = 'No matching tracks';
            insightText.Value = {'No tracks match your search and genre selection.'};
            cla(axPopular); cla(axFeatures); cla(axGenres);
            title(axPopular,'No matching tracks','Color',white);
            title(axFeatures,'No matching tracks','Color',white);
            title(axGenres,'No matching tracks','Color',white);
            return;
        end

        updateDashboard(currentData);
        statusLabel.Text = sprintf('%d matching tracks',height(currentData));
        if strlength(query) == 0 && chosenGenre == "All genres"
            statusLabel.Text = sprintf('%d tracks shown',height(currentData));
        end
    end

    function resetDashboard(~,~)
        searchBox.Value = '';
        genreDropdown.Value = 'All genres';
        updateDashboard(data);
        statusLabel.Text = sprintf('%d tracks shown',height(data));
    end

    function showOverview(~,~)
        btnOverview.BackgroundColor = greenDark;
        btnExplore.BackgroundColor = sidebarBg;
        btnInsights.BackgroundColor = sidebarBg;
        statusLabel.Text = 'Overview';
        updateDashboard(data);
    end

    function showExplore(~,~)
        btnOverview.BackgroundColor = sidebarBg;
        btnExplore.BackgroundColor = greenDark;
        btnInsights.BackgroundColor = sidebarBg;
        searchBox.Value = '';
        statusLabel.Text = 'Enter a song or artist, then Search';
        % Keep current charts; the search bar is ready for input.
        uialert(fig,'Use the search field at the bottom to search by song title or artist. You can also choose a genre.','Explore Music');
    end

    function showInsights(~,~)
        btnOverview.BackgroundColor = sidebarBg;
        btnExplore.BackgroundColor = sidebarBg;
        btnInsights.BackgroundColor = greenDark;
        updateInsights(data);
        statusLabel.Text = 'Insights for all tracks';
        uialert(fig,'The Music Insights panel shows statistics calculated from the current dataset. Use Search or the genre dropdown to explore a subset.','Discover Trends');
    end
end
