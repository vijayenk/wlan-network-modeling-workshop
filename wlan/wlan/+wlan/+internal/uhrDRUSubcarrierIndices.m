function indicesDRU = uhrDRUSubcarrierIndices(cbw,dbw,ruSize,ruIndex)
%uhrDRUSubcarrierIndices DRU subcarrier indices as per IEEE P802.11bn/D0.1, Section 38.3.2.1
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
% 	INDICESDRU = uhrDRUSubcarrierIndices(CBW,DBW,RUSIZE,RUINDEX) returns
%   the indices for the RU specified by RUINDEX.
%
%   CBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.
%
% 	DBW is the distribution bandwidth and must be 20, 40, or 80.
%
% 	RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, or 484.
%
%   RUINDEX is the 1-based RU index. It must be the same size as RUSIZE.
%
%   Copyright 2025 The MathWorks, Inc.

%#codegen

switch cbw
    case 20
        I = druToneIndices20MHz;
        switch ruSize
            case 26
                idx = I.DBW20RUSize26;
            case 52
                idx = I.DBW20RUSize52;
            case 106
               idx = I.DBW20RUSize106;
            otherwise
                error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
        end
    case 40
        I = druToneIndices40MHz;
        switch ruSize
            case 26
                idx = I.DBW40RUSize26;
            case 52
                idx = I.DBW40RUSize52;
            case 106
               idx = I.DBW40RUSize106;
            case 242
                idx = I.DBW40RUSize242;
            otherwise
                error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
        end
    case 80
        if dbw==20
            I = druToneIndices20MHz;
            switch ruSize
                case 26
                    d26 = I.DBW20RUSize26;
                    idx = [d26-380 d26-133 nan(26,1) d26+132 d26+379];
                case 52
                    d52 = I.DBW20RUSize52;
                    idx = [d52-380 d52-133 d52+132 d52+379];
                case 106
                    d106 = I.DBW20RUSize106;
                    idx = [d106-380 d106-133 d106+132 d106+379];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        elseif dbw==40
            I = druToneIndices40MHz;
            switch ruSize
                case 26
                    d26 = I.DBW40RUSize26;
                    idx = [d26-256 nan(26,1) d26+256];
                case 52
                    d52 = I.DBW40RUSize52;
                    idx = sort([d52-256 d52+256]);
                case 106
                    d106 = I.DBW40RUSize106;
                    idx = sort([d106-256 d106+256]);
                case 242
                    d242 = I.DBW40RUSize242;
                    idx = sort([d242-256 d242+256]);
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        else % 80 MHz
            I = druToneIndices80MHz;
            switch ruSize
                case 52
                    idx = I.DBW80RUSize52;
                case 106
                    idx = I.DBW80RUSize106;
                case 242
                    idx = I.DBW80RUSize242;
                case 484
                    idx = I.DBW80RUSize484;
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        end
    case 160
        if dbw==20
            I = druToneIndices20MHz;
            switch ruSize
                case 26
                    d26 = I.DBW20RUSize26;
                    idx = [d26-892 d26-645 nan(26,1) d26-380 d26-133, ...
                           d26+132 d26+379 nan(26,1) d26+644 d26+891];
                case 52
                    d52 = I.DBW20RUSize52;
                    idx = [d52-892 d52-645 d52-380 d52-133, ...
                           d52+132 d52+379 d52+644 d52+891];
                case 106
                    d106 = I.DBW20RUSize106;
                    idx = [d106-892 d106-645 d106-380 d106-133, ...
                           d106+132 d106+379 d106+644 d106+891];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        elseif dbw==40
            I = druToneIndices40MHz;
            switch ruSize
                case 26
                    d26 = I.DBW40RUSize26;
                    idx = [d26-768 nan(26,1) d26-256 d26+256 nan(26,1) d26+768];
                case 52
                     d52 = I.DBW40RUSize52;
                     idx = [d52-768 d52-256 d52+256 d52+768];
                case 106
                    d106 = I.DBW40RUSize106;
                    idx = [d106-768 d106-256 d106+256 d106+768];
                case 242
                    d242 = I.DBW40RUSize242;
                    idx = [d242-768 d242-256 d242+256 d242+768];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        else % dbw==80
            I = druToneIndices80MHz;
            switch ruSize
                case 52
                    d52 = I.DBW80RUSize52;
                    idx = [d52-512 d52+512];
                case 106
                    d106 = I.DBW80RUSize106;
                    idx = [d106-512 d106+512];
                case 242
                    d242 = I.DBW80RUSize242;
                    idx = [d242-512 d242+512];
                case 484
                    d484 = I.DBW80RUSize484;
                    idx = [d484-512 d484+512];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        end
    otherwise % 320 MHz
        % IEEE P802.11bn/D0.1, Table 38-7
        if dbw==20
            I = druToneIndices20MHz;
            switch ruSize
                case 26
                    d26 = I.DBW20RUSize26;
                    idx = [d26-1916 d26-1669 nan(26,1) d26-1404 d26-1157, ...
                           d26-892  d26-645  nan(26,1) d26-380  d26-133, ...
                           d26+132  d26+379  nan(26,1) d26+644  d26+891, ...
                           d26+1156 d26+1403 nan(26,1) d26+1668 d26+1915];
                case 52
                    d52 = I.DBW20RUSize52;
                    idx = [d52-1916 d52-1669 d52-1404 d52-1157, ...
                           d52-892  d52-645  d52-380  d52-133, ...
                           d52+132  d52+379  d52+644  d52+891, ...
                           d52+1156 d52+1403 d52+1668 d52+1915];
                case 106
                    d106 = I.DBW20RUSize106;
                    idx = [d106-1916 d106-1669 d106-1404 d106-1157, ...
                           d106-892  d106-645  d106-380  d106-133, ...
                           d106+132  d106+379  d106+644  d106+891, ...
                           d106+1156 d106+1403 d106+1668 d106+1915];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        elseif dbw==40
            I = druToneIndices40MHz;
            switch ruSize
                case 26
                    d26 = I.DBW40RUSize26;
                    idx = [d26-1792 nan(26,1) d26-1280 d26-768 nan(26,1) d26-256, ...
                           d26+256  nan(26,1) d26+768  d26+1280  nan(26,1) d26+1792];
                case 52
                    d52 = I.DBW40RUSize52;
                    idx = [d52-1792 d52-1280 d52-768 d52-256, ...
                           d52+256  d52+768  d52+1280  d52+1792];
                case 106
                    d106 = I.DBW40RUSize106;
                    idx = [d106-1792 d106-1280 d106-768 d106-256, ...
                           d106+256  d106+768  d106+1280  d106+1792];
                case 242
                    d242 = I.DBW40RUSize242;
                    idx = [d242-1792 d242-1280 d242-768 d242-256, ...
                           d242+256  d242+768  d242+1280  d242+1792];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        else % dbw==80
            I = druToneIndices80MHz;
            switch ruSize
                case 52
                    d52 = I.DBW80RUSize52;
                    idx = [d52-1536 d52-512 d52+512 d52+1536];
                case 106
                    d106 = I.DBW80RUSize106;
                    idx = [d106-1536 d106-512 d106+512 d106+1536];
                case 242
                    d242 = I.DBW80RUSize242;
                    idx = [d242-1536 d242-512 d242+512 d242+1536];
                case 484
                    d242 = I.DBW80RUSize484;
                    idx = [d242-1536 d242-512 d242+512 d242+1536];
                otherwise
                    error('Invalid RUSize for %dMHz channel bandwidth. RUSize must be less than distribution bandwidth(DBW) %dMHz',cbw,dbw);
            end
        end
end

% Return indices for RU index of interest
indicesDRU = idx(:,ruIndex);
end


function s = druToneIndices20MHz
%druToneIndices20MHz 26, 52, 106-Tone DRU indices. IEEE P802.11bn/D0.1, Table 38-4 
    s.DRU1 = [-120:9:-12 6:9:114].';
    s.DRU2 = [-116:9:-8 10:9:118].';
    s.DRU3 = [-118:9:-10 8:9:116].';
    s.DRU4 = [-114:9:-6 12:9:120].';
    s.DRU5 = [-112:9:-4 5:9:113].';
    s.DRU6 = [-119:9:-11 7:9:115].';
    s.DRU7 = [-115:9:-7 11:9:119].';
    s.DRU8 = [-117:9:-9 9:9:117].';
    s.DRU9 = [-113:9:-5 4:9:112].';
    s.DBW20RUSize26 = sort([s.DRU1 s.DRU2 s.DRU3 s.DRU4 s.DRU5 s.DRU6 s.DRU7 s.DRU8 s.DRU9]);
    s.DBW20RUSize52 = sort([ [s.DRU1; s.DRU2] [s.DRU3; s.DRU4] [s.DRU6;s.DRU7] [s.DRU8;s.DRU9] ]);
    s.DBW20RUSize106 = sort([ [s.DRU1; s.DRU2; s.DRU3; s.DRU4; -3; 3] [s.DRU6; s.DRU7; s.DRU8; s.DRU9; -2; 2] ]);
end

function s = druToneIndices40MHz()
%druToneIndices40MHz 26, 52, 106, 242-Tone DRU indices. IEEE P802.11bn/D0.1, Table 38-5 
    s.DRU1 = [-242:18:-26 10:18:226].';
    s.DRU2 = [-233:18:-17 19:18:235].';
    s.DRU3 = [-238:18:-22 14:18:230].';
    s.DRU4 = [-229:18:-13 23:18:239].';
    s.DRU5 = [-225:18:-9 27:18:243].';
    s.DRU6 = [-240:18:-24 12:18:228].';
    s.DRU7 = [-231:18:-15 21:18:237].';
    s.DRU8 = [-236:18:-20 16:18:232].';
    s.DRU9 = [-227:18:-11 25:18:241].';
    
    s.DRU10 = [-241:18:-25 11:18:227].';
    s.DRU11 = [-232:18:-16 20:18:236].';
    s.DRU12 = [-237:18:-21 15:18:231].';
    s.DRU13 = [-228:18:-12 24:18:240].';
    s.DRU14 = [-234:18:-18 18:18:234].';
    s.DRU15 = [-239:18:-23 13:18:229].';
    s.DRU16 = [-230:18:-14 22:18:238].';
    s.DRU17 = [-235:18:-19 17:18:233].';
    s.DRU18 = [-226:18:-10 26:18:242].';
    s.DBW40RUSize26 = [s.DRU1 s.DRU2 s.DRU3 s.DRU4 s.DRU5 s.DRU6 s.DRU7 s.DRU8 s.DRU9  s.DRU10 s.DRU11 s.DRU12 s.DRU13 s.DRU14 s.DRU15 s.DRU16 s.DRU17 s.DRU18];
    s.DBW40RUSize52 = [[-242:9:-17 10:9:235].' [-238:9:-13, 14:9:239].' [-240:9:-15, 12:9:237].' [-236:9:-11, 16:9:241].' [-241:9:-16, 11:9:236].' [-237:9:-12, 15:9:240].' [-239:9:-14, 13:9:238].' [-235:9:-10, 17:9:242].'];
    s.DBW40RUSize106 = sort([ [s.DRU1; s.DRU2; s.DRU3; s.DRU4; -8; 5] [s.DRU6; s.DRU7; s.DRU8; s.DRU9; -6; 7] [s.DRU10; s.DRU11; s.DRU12; s.DRU13; -7; 6] [s.DRU15; s.DRU16; s.DRU17; s.DRU18; -5; 8] ]);
    s.DBW40RUSize242 = sort([ [s.DBW40RUSize106(:,1); s.DBW40RUSize106(:,2); s.DBW40RUSize26(:,5); -244; -4; 3; 9] [s.DBW40RUSize106(:,3); s.DBW40RUSize106(:,4); s.DBW40RUSize26(:,14); -243; -3; 4; 244] ]);
end


function s = druToneIndices80MHz()
%druToneIndices80MHz 26, 52, 106, 242, 484-Tone DRU indices. IEEE P802.11bn/D0.1, Table 38-6 
    s.DRU1 = [-483:36:-51 17:36:449 -467:36:-35 33:36:465].';
    s.DRU2 = [-475:36:-43 25:36:457 -459:36:-27 41:36:473].';
    s.DRU3 = [-479:36:-47 21:36:453 -463:36:-31 37:36:469].';
    s.DRU4 = [-471:36:-39 29:36:461 -455:36:-23 45:36:477].';
    s.DRU5 = [-477:36:-45 23:36:455 -461:36:-29 39:36:471].';
    s.DRU6 = [-469:36:-37 31:36:463 -453:36:-21 47:36:479].';
    s.DRU7 = [-481:36:-49 19:36:451 -465:36:-33 35:36:467].';
    s.DRU8 = [-473:36:-41 27:36:459 -457:36:-25 43:36:475].';
    s.DRU9 = [-482:36:-50 18:36:450 -466:36:-34 34:36:466].';
    s.DRU10 = [-474:36:-42 26:36:458 -458:36:-26 42:36:474].';
    s.DRU11 = [-478:36:-46 22:36:454 -462:36:-30 38:36:470].';
    s.DRU12 = [-470:36:-38 30:36:462 -454:36:-22 46:36:478].';
    s.DRU13 = [-476:36:-44 24:36:456 -460:36:-28 40:36:472].';
    s.DRU14 = [-468:36:-36 32:36:464 -452:36:-20 48:36:480].';
    s.DRU15 = [-480:36:-48 20:36:452 -464:36:-32 36:36:468].';
    s.DRU16 = [-472:36:-40 28:36:460 -456:36:-24 44:36:476].';

    s.DBW80RUSize52 = sort([s.DRU1 s.DRU2 s.DRU3 s.DRU4 s.DRU5 s.DRU6 s.DRU7 s.DRU8 s.DRU9 s.DRU10 s.DRU11 s.DRU12 s.DRU13 s.DRU14 s.DRU15 s.DRU16]);
    s.DBW80RUSize106 = sort([ [s.DRU1; s.DRU2; -495; 485] [s.DRU3; s.DRU4; -491; 489] [s.DRU5; s.DRU6; -489; 491] [s.DRU7; s.DRU8; -493; 487] [s.DRU9; s.DRU10; -494; 486] [s.DRU11; s.DRU12; -490; 490] [s.DRU13; s.DRU14; -488; 492] [s.DRU15; s.DRU16; -492; 488] ]);
    s.DBW80RUSize242 = [ [-499:4:-19 17:4:497].' [-497:4:-17 19:4:499].' [-498:4:-18 18:4:498].' [-496:4:-16, 20:4:500].'];
    s.DBW80RUSize484 = [ [-499:2:-17, 17:2:499].' [-498:2:-16, 18:2:500].'];
end
