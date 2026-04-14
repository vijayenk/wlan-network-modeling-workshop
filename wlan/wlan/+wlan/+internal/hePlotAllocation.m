function hePlotAllocation(cfg,varargin)
%hePlotAllocation Plots the HE or EHT RU allocation for a given configuration object
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   plotAllocation(CFG) plots the RU allocation for a given HE or EHT format
%   configuration object. CFG is the format configuration object of type
%   <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a>, <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or 
%   <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>
%
%   hePlotAllocation(cfg,AX) plots the allocation in the axes specified
%   by AX instead of in the current axes.

%   Copyright 2017-2025 The MathWorks, Inc.

% Definition of the global parameters
allocInfo = ruInfo(cfg);
isEHT = isa(cfg,'wlanEHTMUConfig') || isa(cfg,'wlanEHTTBConfig');
if ~isEHT
    allocInfo.RUIndices = num2cell(allocInfo.RUIndices);
    allocInfo.RUSizes = num2cell(allocInfo.RUSizes);
end
[ruTypeInfo,isMRU] = getTypeInfoRU(allocInfo);

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
Nfft = cbw/20*256;

% Pre-EHT occupied subcarriers
cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfg.ChannelBandwidth);
preEHT = zeros(cfgOFDM.FFTLength,1);
preEHT(cfgOFDM.DataIndices) = 1;
preEHT(cfgOFDM.PilotIndices) = 1;
preEHT = preEHT.*wlan.internal.ehtPreEHTCarrierRotations(cfg);
kPreEHT = find(abs(preEHT)==1)-(cfgOFDM.FFTLength/2+1);
nonContigEnd = [find(diff(kPreEHT)~=1); numel(kPreEHT)];

xoffset = 0.5;

% infoLims contains tuples of channel bandwidth and the minimum RU size for
% which RU information is to be displayed on a patch: [cbw rusize].
infoLims = ...
    [20 26; ...
     40 52; ...
     80 106; ...
    160 242; ...
    320 484];

% Get the start and end subcarrier indices of each subblock
subblock = 80; % Bandwidth of an 80 MHz subblock
numSubblock = floor(cbw/subblock);
nss = 256*subblock/20; % Number of subcarriers to show in a subblock
startIdx = -numSubblock*nss/2:nss:((numSubblock-1)*nss/2-1);
endIdx = (-numSubblock*nss/2+nss-1):nss:((numSubblock-1)*nss/2+nss-1);
scidx = [startIdx' endIdx']; % Each row is a subblock

isHETBNDP = isa(cfg,'wlanHETBConfig') && cfg.FeedbackNDP;

% Initialize the plot
if nargin==1
    f = figure;
    if isEHT
        f.Name = getString(message('wlan:ehtPlotAllocation:FigureTitle'));
    else
        f.Name = getString(message('wlan:hePlotAllocation:FigureTitle'));
    end
    ax = axes(f);
else
    ax = varargin{1};
end
cla(ax,'reset')
disableDefaultInteractivity(ax);

% Plot the pre-EHT occupied subcarriers
startIdx = 1; % The start index of the continuous block of subcarriers
for j = 1:numel(nonContigEnd)
    % Plot a patch of the continuous block of subcarriers
    blkIdx = startIdx:nonContigEnd(j);
    y = [kPreEHT(blkIdx(1)) kPreEHT(blkIdx(end)) kPreEHT(blkIdx(end)) kPreEHT(blkIdx(1))]*4;
    x = [0    0    0.5    0.5];
    patch(ax,x,y,0);
    hold(ax,'on');
    startIdx = nonContigEnd(j)+1;
end

% Plot the EHT occupied subcarriers
bi = 1;
startEndIdx = zeros(0,2);
hRU = gobjects(allocInfo.NumRUs,2); % At most 2 patches per RU
for i = 1:allocInfo.NumRUs
    if ~allocInfo.RUAssigned(i)
        continue
    end
    % Get the active subcarrier indices for the RU
    k = zeros(0,1);
    ruSize = allocInfo.RUSizes{i};
    ruIndices = allocInfo.RUIndices{i};
    
    if isEHT
        for mru=1:numel(ruSize)
            k = [k; wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize(mru),ruIndices(mru))]; %#ok<AGROW> 
        end
    elseif isHETBNDP
        kFull = wlan.internal.heTBNDPSubcarrierIndices(cbw,cfg.RUToneSetIndex,cfg.FeedbackStatus);
        k = puncturedSubcarrierIndices(cfg,kFull);
    else
        kFull = wlan.internal.heRUSubcarrierIndices(cbw,allocInfo.RUSizes{i},allocInfo.RUIndices{i});
        k = puncturedSubcarrierIndices(cfg,kFull);
    end

    % Get the end index of each continuous block of subcarriers within the RU
    nonContigEnd = [find(diff(k)~=1); numel(k)];
    startIdx = 1; % The start index of the continuous block of subcarriers
    for j = 1:numel(nonContigEnd)
        % Plot a patch of the continuous block of subcarriers
        blkIdx = startIdx:nonContigEnd(j);
        startEndIdx(bi,:) = [k(blkIdx(1)) k(blkIdx(end))];
        y = [k(blkIdx(1)) k(blkIdx(end)) k(blkIdx(end)) k(blkIdx(1))];
        x = [0    0    1.5    1.5] + xoffset;

        % Add callback to display RU info in legend when patch clicked
        colorToUse = i;
        hRU(i,j) = patch(ax,x,y,colorToUse);
        hRU(i,j).ButtonDownFcn = @displayRUInfo;
        hRU(i,j).PickableParts = 'all';
        hRU(i,j).UserData.RUNumber = i;

        hold(ax,'on');
        startIdx = nonContigEnd(j)+1;
        bi = bi+1;
    end
end

ylabel(ax,getString(message('wlan:hePlotAllocation:SubcarrierIndex')))
xticks(ax,[])
ylim(ax,[-Nfft/2 Nfft/2-1]);
ax.Box = 'on';
xticks(ax,[0.25 1.25]);

if isEHT
    ax.XTickLabel = {getString(message('wlan:ehtPlotAllocation:PreEHTPortion')),getString(message('wlan:ehtPlotAllocation:EHTPortion'))};
elseif isHETBNDP
    ax.XTickLabel = {getString(message('wlan:hePlotAllocation:PreHEPortion')),getString(message('wlan:hePlotAllocation:HELTF'))};
else
    ax.XTickLabel = {getString(message('wlan:hePlotAllocation:PreHEPortion')),getString(message('wlan:hePlotAllocation:HEPortion'))};
end

h = plot(ax,NaN,NaN,'ow'); % Placeholder for empty legend
h.Marker = 'none';

% Plot text overlay on RU subblocks
plotTextOverlay();

% When initializing create a dummy entry 
lgd = legend(ax,h,' ','Location','southoutside');
if isEHT
    title(lgd,getString(message('wlan:ehtPlotAllocation:LegendTitle')));
else
    title(lgd,getString(message('wlan:hePlotAllocation:LegendTitle')));
end
hold(ax,'off');

if any(cbw==[160 320]) % Display subbblock icons for 160/320 MHz
    tb = axtoolbar(ax,{'export','restoreview'});
    restoreviewbtn = findobj(tb.Children,'Tag','restoreview');
    restoreviewbtn.ButtonPushedFcn = {@restoreview}; % Change the callback function
    btn = gobjects(1,numSubblock);
    for s = numSubblock:-1:1
        btn(s) = axtoolbarbtn(tb,'push');
        btn(s).Icon = ['s' num2str(s) '.png'];
        btn(s).Tooltip = getString(message('wlan:ehtPlotAllocation:ZoomSubblock',s));
        btn(s).UserData = s;
        btn(s).ButtonPushedFcn = @subblockCallback;
    end
else
    tb = axtoolbar(ax,{'export'}); %#ok<NASGU>
end

function subblockCallback(src,event)
    % Set axes and reset text overlay with new view
    ylim(event.Axes,scidx(src.UserData,:));
    plotTextOverlay();
end
function restoreview(~,event)
    % Default ButtonPushedFcn for the reset view toolbar button
    @(e,d)matlab.graphics.controls.internal.resetHelper(d.Axes,true);
    % Reset axes and text overlay
    ylim(event.Axes,[scidx(1) scidx(end)]);
    plotTextOverlay();
end
function plotTextOverlay()
    % Plot text overlay on RU subblocks. The text is only displayed
    % if the bandwidth of the view and RU size allow.

    % Delete any existing text overlays on RUs as we recreate them when
    % zooming in or out
    hExistingText = findobj(ax,'Tag','RUText');
    for a = 1:numel(hExistingText)
        delete(hExistingText(a));
    end

    userIdx = 1;
    for ii = 1:allocInfo.NumRUs
        if ~allocInfo.RUAssigned(i)
            continue
        end
        % Text with user numbers associated with RU
        if allocInfo.NumUsersPerRU(ii)==1
            userTxt = getString(message('wlan:ehtPlotAllocation:UserNumber',userIdx));
            % String with RU number, user index and RU size displayed on patch
            ruPatchTxt = getString(message('wlan:ehtPlotAllocation:MRUInfoUser',ii,ruTypeInfo(ii),userIdx));
        else
            userTxt = getString(message('wlan:ehtPlotAllocation:UserNumbers',userIdx,userIdx+allocInfo.NumUsersPerRU(ii)-1));
            % String with RU number, user index and RU size displayed on patch
            ruPatchTxt = getString(message('wlan:ehtPlotAllocation:MRUInfoUsers',ii,ruTypeInfo(ii),userIdx,userIdx+allocInfo.NumUsersPerRU(ii)-1));
        end
        % String with detailed RU size and index making up MRU displayed in legend
        if isMRU(ii)
            legendRUTxt = getString(message('wlan:ehtPlotAllocation:MRUText',ii));
        else
            legendRUTxt = getString(message('wlan:ehtPlotAllocation:RUText',ii));
        end
        legendRUDetailTxt = strings(1,0);
        for jj = 1:numel(allocInfo.RUSizes{ii})
            legendRUDetailTxt = [legendRUDetailTxt getString(message('wlan:ehtPlotAllocation:LegendRUDetailText',allocInfo.RUSizes{ii}(jj),allocInfo.RUIndices{ii}(jj)))]; %#ok<AGROW>
            if jj~=numel(allocInfo.RUSizes{ii})
                % Separate RUs within an RU by +
                legendRUDetailTxt = [legendRUDetailTxt "+"]; %#ok<AGROW> 
            end
            if jj==2 && numel(allocInfo.RUSizes{ii})>3
                % If lots of RUs in an M-RU split up legend over two lines
                legendRUDetailTxt(end) = legendRUDetailTxt(end)+newline;
            end
        end
        legendRUDetailTxt = join(legendRUDetailTxt); % Concatenate all RUs making up an M-RU separated by a space

        if isHETBNDP
            legendTxt = getString(message('wlan:hePlotAllocation:HTBNDPInfo',cfg.RUToneSetIndex,double(cfg.FeedbackStatus))); % Force double for message catalog (logical not supported)
        else
            legendTxt = join([legendRUTxt legendRUDetailTxt userTxt],", ");
        end

        % Get the equivalent bandwidth for the current view/zoom
        cyl = ylim(ax);
        cbwView = min(cbw,(diff(cyl)+1)/nss*subblock);

        for jj = 1:size(hRU,2) % Each column is a patch making up an RU
            if isPatch(hRU(ii,jj))
                % Check if RU visible in limits
                vert = hRU(ii,jj).Vertices([1 2],2);
                if max(vert)>max(cyl) || min(vert)<min(cyl) 
                    continue
                end

                % Store useful data in patch UserData to be used in
                % ButtonDownFcn callback
                hRU(ii,jj).UserData.RUText = legendTxt;   % Text for selected RU info
                hRU(ii,jj).UserData.isSelected = false;   % Is RU selected
                hRU(ii,jj).UserData.hPlaceholderLine = h; % Handle to placeholder for empty legend

                % Display RU info on a patch unless the patch is too small. If
                % an RU spans multiple patches, print RU info in each patch.
                % Use the vertices to print in the middle of each RU.
                if (hRU(ii,jj).Vertices(2,2)-hRU(ii,jj).Vertices(1,2)+1)<infoLims(cbwView == infoLims(:,1),2)
                    continue % Do not print text on patch
                end
                xMiddle = hRU(ii,jj).Vertices(1,1)+(hRU(ii,jj).Vertices(end,1)-hRU(ii,jj).Vertices(1,1))/2;
                yMiddle = hRU(ii,jj).Vertices(1,2)+(hRU(ii,jj).Vertices(2,2)-hRU(ii,jj).Vertices(1,2))/2;
                text(ax,xMiddle,yMiddle,ruPatchTxt,'HorizontalAlignment','center','Color','k','Tag','RUText','PickableParts','none');
            end
        end
        userIdx = userIdx+allocInfo.NumUsersPerRU(ii);
    end
end

end

function displayRUInfo(src,~)  
    ax = src.Parent; % Handle to axis
    f = ax.Parent;   % Handle to figure

    % Determine if control key pressed
    modifiers = get(f,'CurrentModifier');
    ctrlPressed = ismember('control',modifiers);

    % If a RU is currently selected and is ctrl-clicked then remove it from
    % those displayed with the legend
    if ctrlPressed && src.UserData.isSelected
        unselectPatch = true;
    else
        unselectPatch = false;
    end

    % Get handles to patch objects which show RUs
    hPatch = findobj(f,'Type','Patch');
    % Remove patches which are not RUs
    rmIdx = false(numel(hPatch),1);
    for i = 1:numel(hPatch)
        rmIdx(i) = isempty(hPatch(i).UserData);
    end
    hPatch(rmIdx) = [];

    % Reset all patches to have a default edge color and width if ctrl key
    % is not held. This means that only the RU clicked on will be
    % highlighted
    if ~ctrlPressed
        for i = 1:numel(hPatch)
            resetPatch(hPatch(i));
        end
    end

    % Select or unselect the patch clicked on depending if the ctrl is
    % pressed or not
    for i = 1:numel(hPatch)
        if hPatch(i).UserData.RUNumber==src.UserData.RUNumber
            % If any patch matches the patch clicked on then select or
            % unselect all patches related to that RU. A patch is
            % highlighted when selected.
            if unselectPatch
                resetPatch(hPatch(i));
            else
                selectPatch(hPatch(i));
            end
        end
    end
    
    % Create an array of legend text strings and handles to patches which
    % are selected
    strLegend = strings(1,0);
    hPatchLegend = gobjects(0,1);
    for i = 1:numel(hPatch)
        if hPatch(i).UserData.isSelected
            strLegend = [strLegend hPatch(i).UserData.RUText]; %#ok<AGROW>
            hPatchLegend = [hPatchLegend hPatch(i)]; %#ok<AGROW>
        end
    end
    % Remove duplicates caused by multiple patches per RU so they are not
    % displayed in the legend
    [~,uniqueIdx] = unique(strLegend);
    strLegend = strLegend(uniqueIdx);
    hPatchLegend = hPatchLegend(uniqueIdx);

    % If no RUs are selected then display a special message of the legend
    if isempty(hPatchLegend)
        hPatchLegend = src.UserData.hPlaceholderLine;
        strLegend = ' ';
    end

    % Display the RU information in the legend
    legend(ax,hPatchLegend,strLegend,'Location','southoutside')
end

function out = isPatch(in)
    % Returns true if the object passed in is a patch
    out = isa(in,'matlab.graphics.primitive.Patch');
end

function selectPatch(hPatch)
    % Select/highlight patch
    matlab.graphics.internal.themes.specifyThemePropertyMappings(hPatch,'EdgeColor','--mw-graphics-colorSpace-rgb-red');
    hPatch.LineWidth = 2.5;
    hPatch.UserData.isSelected = true;
end

function resetPatch(hPatch)
    % Unselect/reset patch
    matlab.graphics.internal.themes.specifyThemePropertyMappings(hPatch,'EdgeColor','remove');
    set(hPatch,'LineWidth','default');
    hPatch.UserData.isSelected = false;
end

function [ruTypeInfo,isMRU] = getTypeInfoRU(allocInfo)
    ruTypeInfo = strings(1,allocInfo.NumRUs);
    isMRU = true(1,allocInfo.NumRUs);
    for ru = 1:allocInfo.NumRUs
        if numel(allocInfo.RUSizes{ru})==1
            ruTypeInfo(ru) = num2str(allocInfo.RUSizes{ru});
            isMRU(ru) = false;
            continue
        end
        switch sum(allocInfo.RUSizes{ru})
            case 26+52
                ruTypeInfo(ru) = "52+26";
            case 26+106
                ruTypeInfo(ru) = "106+26";
            case 242+484
                ruTypeInfo(ru) = "484+242";
            case 484+996
                ruTypeInfo(ru) = "996+484";
            case 242+484+996
                ruTypeInfo(ru) = "996+484+242";
            case 2*996
                ruTypeInfo(ru) = "2*996";
            case 2*996+484
                ruTypeInfo(ru) = "2*996+484";
            case 3*996
                ruTypeInfo(ru) = "3*996";
            otherwise % 3*996+484
                ruTypeInfo(ru) = "3*996+484";
        end
    end
end

function k = puncturedSubcarrierIndices(cfg,kFull)
    kRUPuncture = wlan.internal.hePuncturedRUSubcarrierIndices(cfg);
    if ~isempty(kRUPuncture)
        k = setdiff(kFull,kRUPuncture); % Discard punctured subcarriers
    else
        k = kFull;
    end
end