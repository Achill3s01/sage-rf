function main()
% SAGE-RF LITE
% Unified Digital Signal Processing Workstation
%
% Integrated modules:
%   1. Signal Viewer
%   2. FFT Analyzer
%   3. Spectrogram Analyzer
%   4. Filter Designer
%   5. Speech Enhancement (next integration)
%
% Shared audio loading across all integrated modules.

    %% PROJECT SETUP

    projectRoot = fileparts(mfilename('fullpath'));
    modulesFolder = fullfile(projectRoot, 'modules');

    if isfolder(modulesFolder)
        addpath(modulesFolder);
    end

    %% APPLICATION STATE

    app = struct();

    app.audio = [];
    app.fs = [];
    app.fileName = '';

    app.currentModule = 'Dashboard';

    app.modulePanels = struct();
    app.moduleButtons = struct();

    app.signalViewerRefresh = [];
    app.fftAnalyzerRefresh = [];
    app.spectrogramRefresh = [];
    app.filterDesignerRefresh = [];
    app.speechEnhancementRefresh = [];

    %% COLORS

    C.bg = [0.055 0.075 0.105];
    C.sidebar = [0.075 0.105 0.15];
    C.toolbar = [0.085 0.12 0.17];
    C.panel = [0.085 0.13 0.19];

    C.accent = [0.08 0.43 0.68];
    C.active = [0.08 0.30 0.46];
    C.stop = [0.65 0.20 0.20];

    C.white = [0.93 0.96 0.99];
    C.text = [0.82 0.88 0.94];
    C.muted = [0.58 0.68 0.79];

    %% MAIN WINDOW

    screen = get(groot, 'ScreenSize');

    figW = min(1440, max(1050, screen(3)-100));
    figH = min(900, max(680, screen(4)-140));

    figX = max(30, round((screen(3)-figW)/2));
    figY = max(50, round((screen(4)-figH)/2));

    app.fig = uifigure( ...
        'Name', 'SAGE-RF Lite | DSP Workstation', ...
        'Position', [figX figY figW figH], ...
        'Color', C.bg, ...
        'Resize', 'on');

    %% ROOT LAYOUT

    root = uigridlayout(app.fig, [1 2]);

    root.ColumnWidth = {230, '1x'};
    root.RowHeight = {'1x'};

    root.Padding = [0 0 0 0];
    root.ColumnSpacing = 0;

    root.BackgroundColor = C.bg;

    %% SIDEBAR

    sidebar = uipanel(root, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.sidebar);

    sidebar.Layout.Row = 1;
    sidebar.Layout.Column = 1;

    sideGrid = uigridlayout(sidebar, [10 1]);

    sideGrid.RowHeight = {72, 28, ...
        42, 42, 42, 42, 42, 42, ...
        '1x', 34};

    sideGrid.Padding = [14 14 14 14];
    sideGrid.RowSpacing = 7;

    sideGrid.BackgroundColor = C.sidebar;

    %% BRAND

    brand = uipanel(sideGrid, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.sidebar);

    brand.Layout.Row = 1;

    brandGrid = uigridlayout(brand, [2 1]);

    brandGrid.RowHeight = {34, 20};
    brandGrid.Padding = [0 3 0 0];
    brandGrid.RowSpacing = 0;

    brandGrid.BackgroundColor = C.sidebar;

    uilabel(brandGrid, ...
        'Text', 'SAGE-RF LITE', ...
        'FontSize', 18, ...
        'FontWeight', 'bold', ...
        'FontColor', [0.28 0.72 0.96], ...
        'BackgroundColor', C.sidebar);

    uilabel(brandGrid, ...
        'Text', 'DSP WORKSTATION', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.sidebar);

    %% NAVIGATION LABEL

    sectionLabel = uilabel(sideGrid, ...
        'Text', 'WORKSPACES', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'FontColor', [0.48 0.60 0.72], ...
        'BackgroundColor', C.sidebar);

    sectionLabel.Layout.Row = 2;

    %% NAVIGATION BUTTONS

    moduleNames = { ...
        'Dashboard', ...
        'Signal Viewer', ...
        'FFT Analyzer', ...
        'Spectrogram', ...
        'Filter Designer', ...
        'Speech Enhancement'};

    moduleIcons = {'⌂','〰','∿','▥','≋','◖'};

    for k = 1:numel(moduleNames)

        key = moduleKey(moduleNames{k});

        btn = uibutton(sideGrid, 'push', ...
            'Text', sprintf('%s   %s', ...
                moduleIcons{k}, moduleNames{k}), ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 11, ...
            'FontColor', C.text, ...
            'BackgroundColor', C.panel, ...
            'ButtonPushedFcn', ...
                @(src,event) navigate(moduleNames{k}));

        btn.Layout.Row = k + 2;

        app.moduleButtons.(key) = btn;

    end

    %% SIDEBAR FOOTER

    footer = uilabel(sideGrid, ...
        'Text', 'LOCAL PROCESSING  |  MATLAB', ...
        'FontSize', 8, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.sidebar);

    footer.Layout.Row = 10;

    %% MAIN CONTENT AREA

    content = uigridlayout(root, [2 1]);

    content.Layout.Row = 1;
    content.Layout.Column = 2;

    content.RowHeight = {72, '1x'};

    content.Padding = [0 0 0 0];
    content.RowSpacing = 0;

    content.BackgroundColor = C.bg;

    %% TOP TOOLBAR

    toolbar = uipanel(content, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.toolbar);

    toolbar.Layout.Row = 1;

    toolGrid = uigridlayout(toolbar, [1 4]);

    toolGrid.ColumnWidth = {'1x', 140, 110, 150};

    toolGrid.Padding = [22 12 22 12];
    toolGrid.ColumnSpacing = 12;

    toolGrid.BackgroundColor = C.toolbar;

    %% PAGE TITLE

    titleStack = uipanel(toolGrid, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.toolbar);

    titleStack.Layout.Column = 1;

    titleGrid = uigridlayout(titleStack, [2 1]);

    titleGrid.RowHeight = {27, 18};

    titleGrid.Padding = [0 0 0 0];
    titleGrid.RowSpacing = 0;

    titleGrid.BackgroundColor = C.toolbar;

    app.pageTitle = uilabel(titleGrid, ...
        'Text', 'Dashboard', ...
        'FontSize', 17, ...
        'FontWeight', 'bold', ...
        'FontColor', C.white, ...
        'BackgroundColor', C.toolbar);

    app.fileInfo = uilabel(titleGrid, ...
        'Text', 'No audio loaded', ...
        'FontSize', 9, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.toolbar);

    %% LOAD AUDIO BUTTON

    loadButton = uibutton(toolGrid, 'push', ...
        'Text', '＋  Load Audio', ...
        'FontWeight', 'bold', ...
        'FontSize', 10, ...
        'FontColor', [1 1 1], ...
        'BackgroundColor', C.accent, ...
        'ButtonPushedFcn', @(src,event) loadAudio());

    loadButton.Layout.Column = 2;

    %% STOP AUDIO BUTTON

    stopButton = uibutton(toolGrid, 'push', ...
        'Text', '■  Stop Audio', ...
        'FontWeight', 'bold', ...
        'FontSize', 10, ...
        'FontColor', [1 1 1], ...
        'BackgroundColor', C.stop, ...
        'ButtonPushedFcn', @(src,event) stopAudio());

    stopButton.Layout.Column = 3;

    %% SAMPLE RATE DISPLAY

    app.sampleRateLabel = uilabel(toolGrid, ...
        'Text', 'Fs: —', ...
        'HorizontalAlignment', 'right', ...
        'FontSize', 10, ...
        'FontColor', C.text, ...
        'BackgroundColor', C.toolbar);

    app.sampleRateLabel.Layout.Column = 4;

    %% WORKSPACE CONTAINER

    workspace = uipanel(content, ...
        'BorderType', 'none', ...
        'BackgroundColor', C.bg);

    workspace.Layout.Row = 2;

    workspaceGrid = uigridlayout(workspace, [1 1]);

    workspaceGrid.Padding = [22 20 22 18];

    workspaceGrid.BackgroundColor = C.bg;

    %% CREATE MODULE PANELS

    for k = 1:numel(moduleNames)

        key = moduleKey(moduleNames{k});

        panel = uipanel(workspaceGrid, ...
            'BorderType', 'none', ...
            'BackgroundColor', C.bg, ...
            'Visible', 'off');

        panel.Layout.Row = 1;
        panel.Layout.Column = 1;

        app.modulePanels.(key) = panel;

    end

    %% BUILD DASHBOARD

    buildDashboard(app.modulePanels.dashboard);

    %% SIGNAL VIEWER INTEGRATION

    signalViewerFile = fullfile( ...
        modulesFolder, 'create_signal_viewer.m');

    if isfile(signalViewerFile)

        try

            app.signalViewerRefresh = create_signal_viewer( ...
                app.modulePanels.signal_viewer, ...
                @getAudioData);

        catch ME

            warning('SAGE:SignalViewer', ...
                'Signal Viewer could not be initialized: %s', ...
                ME.message);

            buildPlaceholder( ...
                app.modulePanels.signal_viewer, ...
                'Signal Viewer', ...
                'Signal Viewer initialization failed.', ...
                ME.message);

        end

    else

        buildPlaceholder( ...
            app.modulePanels.signal_viewer, ...
            'Signal Viewer', ...
            'Inspect the loaded signal in the time domain.', ...
            'Missing modules/create_signal_viewer.m');

    end

    %% FFT ANALYZER INTEGRATION

    fftAnalyzerFile = fullfile( ...
        modulesFolder, 'create_fft_analyzer.m');

    if isfile(fftAnalyzerFile)

        try

            app.fftAnalyzerRefresh = create_fft_analyzer( ...
                app.modulePanels.fft_analyzer, ...
                @getAudioData);

        catch ME

            warning('SAGE:FFTAnalyzer', ...
                'FFT Analyzer could not be initialized: %s', ...
                ME.message);

            buildPlaceholder( ...
                app.modulePanels.fft_analyzer, ...
                'FFT Analyzer', ...
                'FFT Analyzer initialization failed.', ...
                ME.message);

        end

    else

        buildPlaceholder( ...
            app.modulePanels.fft_analyzer, ...
            'FFT Analyzer', ...
            'Explore the frequency content of your signal.', ...
            'Missing modules/create_fft_analyzer.m');

    end

    %% SPECTROGRAM INTEGRATION

    spectrogramFile = fullfile( ...
        modulesFolder, 'create_spectrogram_analyzer.m');

    if isfile(spectrogramFile)

        try

            app.spectrogramRefresh = create_spectrogram_analyzer( ...
                app.modulePanels.spectrogram, ...
                @getAudioData);

        catch ME

            warning('SAGE:Spectrogram', ...
                'Spectrogram could not be initialized: %s', ...
                ME.message);

            buildPlaceholder( ...
                app.modulePanels.spectrogram, ...
                'Spectrogram Analyzer', ...
                'Spectrogram initialization failed.', ...
                ME.message);

        end

    else

        buildPlaceholder( ...
            app.modulePanels.spectrogram, ...
            'Spectrogram Analyzer', ...
            'Inspect frequency content over time.', ...
            'Missing modules/create_spectrogram_analyzer.m');

    end

    %% FILTER DESIGNER INTEGRATION

    filterDesignerFile = fullfile( ...
        modulesFolder, 'create_filter_designer.m');

    if isfile(filterDesignerFile)

        try

            app.filterDesignerRefresh = create_filter_designer( ...
                app.modulePanels.filter_designer, ...
                @getAudioData);

        catch ME

            warning('SAGE:FilterDesigner', ...
                'Filter Designer could not be initialized: %s', ...
                ME.message);

            buildPlaceholder( ...
                app.modulePanels.filter_designer, ...
                'Filter Designer', ...
                'Filter Designer initialization failed.', ...
                ME.message);

        end

    else

        buildPlaceholder( ...
            app.modulePanels.filter_designer, ...
            'Filter Designer', ...
            'Design and apply FIR or IIR filters.', ...
            'Missing modules/create_filter_designer.m');

    end

    %% SPEECH ENHANCEMENT INTEGRATION

    speechEnhancementFile = fullfile( ...
        modulesFolder, 'create_speech_enhancement.m');

    if isfile(speechEnhancementFile)
        try
            app.speechEnhancementRefresh = create_speech_enhancement( ...
                app.modulePanels.speech_enhancement, @getAudioData);
        catch ME
            warning('SAGE:SpeechEnhancement', ...
                'Speech Enhancement could not be initialized: %s', ME.message);
            buildPlaceholder(app.modulePanels.speech_enhancement, ...
                'Speech Enhancement', ...
                'Reduce stationary background noise.', ME.message);
        end
    else
        buildPlaceholder(app.modulePanels.speech_enhancement, ...
            'Speech Enhancement', ...
            'Reduce stationary background noise.', ...
            'Missing modules/create_speech_enhancement.m');
    end

    %% INITIAL NAVIGATION

    navigate('Dashboard');

    %% =========================================================
    % NAVIGATION FUNCTION
    % ==========================================================

    function navigate(moduleName)

        key = moduleKey(moduleName);

        app.currentModule = moduleName;

        % Hide all workspaces.

        panelKeys = fieldnames(app.modulePanels);

        for j = 1:numel(panelKeys)
            app.modulePanels.(panelKeys{j}).Visible = 'off';
        end

        % Show selected workspace.

        app.modulePanels.(key).Visible = 'on';

        app.pageTitle.Text = moduleName;

        % Update sidebar appearance.

        buttonKeys = fieldnames(app.moduleButtons);

        for j = 1:numel(buttonKeys)

            app.moduleButtons.(buttonKeys{j}).BackgroundColor = C.panel;

            app.moduleButtons.(buttonKeys{j}).FontColor = C.text;

        end

        app.moduleButtons.(key).BackgroundColor = C.active;

        app.moduleButtons.(key).FontColor = [1 1 1];

        % Refresh selected module.

        switch key

            case 'signal_viewer'

                refreshIfAvailable(app.signalViewerRefresh);

            case 'fft_analyzer'

                refreshIfAvailable(app.fftAnalyzerRefresh);

            case 'spectrogram'

                refreshIfAvailable(app.spectrogramRefresh);

            case 'filter_designer'

                refreshIfAvailable(app.filterDesignerRefresh);

            case 'speech_enhancement'

                refreshIfAvailable(app.speechEnhancementRefresh);

        end

    end

    %% =========================================================
    % LOAD AUDIO FUNCTION
    % ==========================================================

    function loadAudio()

        [file, path] = uigetfile( ...
            { ...
            '*.wav;*.flac;*.mp3;*.m4a;*.ogg', ...
            'Supported Audio Files'; ...
            '*.*', 'All Files' ...
            }, ...
            'Select Audio File');

        if isequal(file, 0)
            return;
        end

        try

            fullFileName = fullfile(path, file);

            [x, fs] = audioread(fullFileName);

            if isempty(x) || ...
                    ~isnumeric(x) || ...
                    ~isreal(x) || ...
                    any(~isfinite(x(:))) || ...
                    ~isfinite(fs) || fs <= 0

                error('Invalid audio data or sampling frequency.');

            end

            % Stop previous playback.

            stopAudio();

            % Store shared audio.

            app.audio = x;
            app.fs = fs;
            app.fileName = file;

            duration = size(x, 1) / fs;

            % Update toolbar.

            app.fileInfo.Text = sprintf( ...
                '%s  |  %.2f s  |  %d channel(s)', ...
                file, duration, size(x, 2));

            app.sampleRateLabel.Text = sprintf('Fs: %g Hz', fs);

            % Update dashboard.

            updateDashboardAudioInfo();

            % Refresh integrated modules.

            refreshIfAvailable(app.signalViewerRefresh);

            refreshIfAvailable(app.fftAnalyzerRefresh);

            refreshIfAvailable(app.spectrogramRefresh);

            refreshIfAvailable(app.filterDesignerRefresh);

            refreshIfAvailable(app.speechEnhancementRefresh);

        catch ME

            uialert(app.fig, ...
                ME.message, ...
                'Audio Loading Error', ...
                'Icon', 'error');

        end

    end

    %% =========================================================
    % STOP AUDIO FUNCTION
    % ==========================================================

    function stopAudio()

        try

            % Stop MATLAB sound() playback.

            clear sound;

            drawnow;

        catch ME

            warning('SAGE:StopAudio', ...
                'Could not stop audio playback: %s', ME.message);

        end

    end

    %% =========================================================
    % SHARED AUDIO GETTER
    % ==========================================================

    function [x, fs, fileName] = getAudioData()

        x = app.audio;
        fs = app.fs;
        fileName = app.fileName;

    end

    %% =========================================================
    % MODULE REFRESH HELPER
    % ==========================================================

    function refreshIfAvailable(refreshFcn)

        if isa(refreshFcn, 'function_handle')

            try

                refreshFcn();

            catch ME

                warning('SAGE:ModuleRefresh', ...
                    'Module refresh failed: %s', ME.message);

            end

        end

    end

    %% =========================================================
    % DASHBOARD AUDIO UPDATE
    % ==========================================================

    function updateDashboardAudioInfo()

        if isempty(app.audio)

            app.dashFileLabel.Text = 'No audio loaded';

            app.dashStatsLabel.Text = ...
                'Load an audio file to begin analysis.';

            return;

        end

        duration = size(app.audio, 1) / app.fs;

        app.dashFileLabel.Text = app.fileName;

        app.dashStatsLabel.Text = sprintf( ...
            '%.2f seconds  |  %g Hz  |  %d channels  |  %d samples', ...
            duration, app.fs, ...
            size(app.audio, 2), size(app.audio, 1));

    end

    %% =========================================================
    % DASHBOARD
    % ==========================================================

    function buildDashboard(parent)

        g = uigridlayout(parent, [4 1]);

        g.RowHeight = {90, 100, '1x', 32};

        g.Padding = [0 0 0 0];

        g.RowSpacing = 16;

        g.BackgroundColor = C.bg;

        % Welcome panel.

        welcome = uipanel(g, ...
            'BorderType', 'none', ...
            'BackgroundColor', [0.075 0.12 0.18]);

        welcome.Layout.Row = 1;

        wg = uigridlayout(welcome, [2 1]);

        wg.RowHeight = {38, 25};

        wg.Padding = [20 12 12 10];

        wg.RowSpacing = 0;

        wg.BackgroundColor = [0.075 0.12 0.18];

        uilabel(wg, ...
            'Text', 'Signal Processing Center', ...
            'FontSize', 23, ...
            'FontWeight', 'bold', ...
            'FontColor', C.white, ...
            'BackgroundColor', [0.075 0.12 0.18]);

        uilabel(wg, ...
            'Text', 'A unified environment for signal inspection, analysis and enhancement.', ...
            'FontSize', 11, ...
            'FontColor', [0.66 0.77 0.87], ...
            'BackgroundColor', [0.075 0.12 0.18]);

        % Audio information card.

        audioCard = uipanel(g, ...
            'Title', ' CURRENT AUDIO', ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'ForegroundColor', [0.55 0.72 0.85], ...
            'BackgroundColor', C.toolbar, ...
            'BorderColor', [0.16 0.23 0.31]);

        audioCard.Layout.Row = 2;

        ag = uigridlayout(audioCard, [2 1]);

        ag.RowHeight = {25, 25};

        ag.Padding = [14 8 10 6];

        ag.RowSpacing = 2;

        ag.BackgroundColor = C.toolbar;

        app.dashFileLabel = uilabel(ag, ...
            'Text', 'No audio loaded', ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'FontColor', C.white, ...
            'BackgroundColor', C.toolbar);

        app.dashStatsLabel = uilabel(ag, ...
            'Text', 'Load an audio file from the toolbar.', ...
            'FontSize', 9, ...
            'FontColor', C.muted, ...
            'BackgroundColor', C.toolbar);

        % Module cards.

        moduleCard = uipanel(g, ...
            'Title', ' DSP MODULES', ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'ForegroundColor', [0.55 0.72 0.85], ...
            'BackgroundColor', C.bg, ...
            'BorderColor', [0.16 0.23 0.31]);

        moduleCard.Layout.Row = 3;

        mg = uigridlayout(moduleCard, [2 3]);

        mg.RowHeight = {'1x', '1x'};

        mg.ColumnWidth = {'1x', '1x', '1x'};

        mg.Padding = [12 12 12 12];

        mg.RowSpacing = 10;

        mg.ColumnSpacing = 10;

        mg.BackgroundColor = C.bg;

        cards = {
            'SIGNAL VIEWER', 'Time-domain inspection', 'Signal Viewer';
            'FFT ANALYZER', 'Frequency-domain analysis', 'FFT Analyzer';
            'SPECTROGRAM', 'Time-frequency analysis', 'Spectrogram';
            'FILTER DESIGNER', 'FIR and IIR filter design', 'Filter Designer';
            'SPEECH ENHANCEMENT', 'Noise reduction workflow', 'Speech Enhancement'
        };

        for n = 1:size(cards, 1)

            cardButton = uibutton(mg, 'push', ...
                'Text', sprintf('%s\n%s', cards{n,1}, cards{n,2}), ...
                'FontSize', 10, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'FontColor', C.text, ...
                'BackgroundColor', C.panel, ...
                'ButtonPushedFcn', ...
                    @(src,event) navigate(cards{n,3}));

            cardButton.Layout.Row = ceil(n/3);

            cardButton.Layout.Column = mod(n-1, 3) + 1;

        end

        % Dashboard tip.

        note = uilabel(g, ...
            'Text', 'TIP  |  Load audio once; integrated modules can access the shared signal.', ...
            'FontSize', 9, ...
            'FontColor', C.muted, ...
            'BackgroundColor', C.bg);

        note.Layout.Row = 4;

    end

    %% =========================================================
    % PLACEHOLDER WORKSPACE
    % ==========================================================

    function buildPlaceholder(parent, heading, subtitle, detail)

        g = uigridlayout(parent, [4 1]);

        g.RowHeight = {50, 35, 110, '1x'};

        g.Padding = [0 0 0 0];

        g.RowSpacing = 12;

        g.BackgroundColor = C.bg;

        uilabel(g, ...
            'Text', heading, ...
            'FontSize', 22, ...
            'FontWeight', 'bold', ...
            'FontColor', C.white, ...
            'BackgroundColor', C.bg);

        uilabel(g, ...
            'Text', subtitle, ...
            'FontSize', 11, ...
            'FontColor', C.muted, ...
            'BackgroundColor', C.bg);

        card = uipanel(g, ...
            'Title', '  MODULE STATUS', ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'ForegroundColor', [0.55 0.72 0.85], ...
            'BackgroundColor', C.toolbar, ...
            'BorderColor', [0.16 0.23 0.31]);

        card.Layout.Row = 3;

        cg = uigridlayout(card, [2 1]);

        cg.RowHeight = {30, '1x'};

        cg.Padding = [16 10 12 10];

        cg.RowSpacing = 4;

        cg.BackgroundColor = C.toolbar;

        uilabel(cg, ...
            'Text', 'WORKSPACE READY FOR INTEGRATION', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'FontColor', [0.31 0.72 0.95], ...
            'BackgroundColor', C.toolbar);

        uilabel(cg, ...
            'Text', detail, ...
            'FontSize', 10, ...
            'FontColor', C.text, ...
            'WordWrap', 'on', ...
            'BackgroundColor', C.toolbar);

        hint = uilabel(g, ...
            'Text', ['This workspace will host the existing DSP module. ' ...
                     'Processing logic will remain separate from the main GUI.'], ...
            'FontSize', 10, ...
            'FontColor', C.muted, ...
            'WordWrap', 'on', ...
            'BackgroundColor', C.bg);

        hint.Layout.Row = 4;

    end

end


%% =========================================================
% MODULE NAME TO STRUCT KEY
% ==========================================================

function key = moduleKey(moduleName)

    switch moduleName

        case 'Dashboard'
            key = 'dashboard';

        case 'Signal Viewer'
            key = 'signal_viewer';

        case 'FFT Analyzer'
            key = 'fft_analyzer';

        case 'Spectrogram'
            key = 'spectrogram';

        case 'Filter Designer'
            key = 'filter_designer';

        case 'Speech Enhancement'
            key = 'speech_enhancement';

        otherwise
            error('Unknown SAGE-RF Lite module: %s', moduleName);

    end

end