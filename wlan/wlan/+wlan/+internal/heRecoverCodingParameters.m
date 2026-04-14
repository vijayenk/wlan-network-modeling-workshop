function userParams = heRecoverCodingParameters(NSYM,a,ruSize,mcs,nss,channelCoding,stbc,dcm,ldpcExtraSymbol,varargin)
%heRecoverCodingParameters Calculate HE and EHT coding parameters from the recovered signal information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   USERPARAMS = heRecoverCodingParams(...) returns a structure USERPARAMS,
%   containing the coding parameters for the given inputs:
%
%   NSYM            - Number of data symbols
%   A               - PreFECPaddingFactor
%   RUSIZE          - Resource unit (RU) size
%   MCS             - Modulation and coding scheme
%   NSS             - Number of spatial streams
%   CHANNELCODING   - Channel coding type
%   STBC            - Space-time block coding
%   DCM             - Dual coded modulation of HE-Data field
%   LDPCEXTRASYMBOL - Extra OFDM symbol
%   EHTDUPMode      - Indicates EHT-DUP mode
%
%   For recovered HE coding parameters USERPARAMS are defined in IEEE
%   Std 802.11ax-2021 BCC interleaver parameters, Section 27.4.3. For
%   recovered EHT coding parameters USERPARAMS are defined in IEEE
%   IEEE P802.11be/D3.0, BCC interleaver, section 36.4.3

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    ehtDUPMode = false;
    if nargin>9
        ehtDUPMode = logical(varargin{1}); % Only applicable for EHT
    end

    if stbc
        % STBC enabled
        mSTBC = 2; % Equation 27-136 of Std 802.11ax-2021.
    else
        mSTBC = 1;
    end

    isLDPC = strcmpi(string(channelCoding),'LDPC'); % For HE and EHT
                                                    % Equation 27-140, 27-142 of Std 802.11ax-2021. Equation 36-114, 36-116 of IEEE P802.11be/D3.0.
    if isLDPC && ldpcExtraSymbol
        if a==1
            aRX = 4;
            NSYMinit = NSYM-mSTBC;
        else % a>1
            aRX = a-1;
            NSYMinit = NSYM;
        end
    else
        aRX = a;
        NSYMinit = NSYM;
    end

    % HE/EHT rate dependent parameters
    rdp = wlan.internal.heRateDependentParameters(ruSize,mcs,nss,dcm);

    NSDSHORT = wlan.internal.heNSDShort(ruSize,dcm,ehtDUPMode);

    % Equation 27-60 of Std 802.11ax-2021. Equation 36-49 of IEEE P802.11be/D3.0
    NCBPSSHORTRX = NSDSHORT*nss*rdp.NBPSCS;
    NDBPSSHORTRX = NCBPSSHORTRX*rdp.Rate;

    if aRX==4
        NDBPSLASTRX = rdp.NDBPS; % Equation 27-141 of Std 802.11ax-2021. Equation 36-116 of IEEE P802.11be/D3.0
    else % < 4
        NDBPSLASTRX = aRX*NDBPSSHORTRX;
    end

    if a<4
        NCBPSLASTRX = a*NCBPSSHORTRX; % Equation 27-67, 27-73 of Std 802.11ax-2021. Equation 36-62 of IEEE P802.11be/D3.0
    else % a=4
        NCBPSLASTRX = rdp.NCBPS;
    end

    if isLDPC
        % Pre-FEC padding factor for LDPC calculations
        aInitcommon = aRX;
    else
        % These values are not used for BCC decoding. Calculated for
        % completeness. Equation 27-65, 27-71, 27-72 of Std 802.11ax-2021.
        % Equation 36-58, 36-59 of IEEE P802.11be/D3.0
        if a==1 && ldpcExtraSymbol
            aInitcommon = 4;
            NSYMinit = NSYM-mSTBC;
        elseif a>1 && ldpcExtraSymbol
            aInitcommon = a-1;
            NSYMinit = NSYM;
        else
            aInitcommon = a;
            NSYMinit = NSYM;
        end
    end

    % Equation 27-77 of Std 802.11ax-2021. Equation 36-52 of IEEE P802.11be/D3.0
    if aInitcommon==4
        NDBPSLASTinitRX = rdp.NDBPS;
        NCBPSLASTinitRX = rdp.NCBPS;
    else % < 4
         % HE/EHT rate dependent parameters
        NDBPSLASTinitRX = aInitcommon*NDBPSSHORTRX;
        NCBPSLASTinitRX = aInitcommon*NCBPSSHORTRX;
    end

    % Equation 27-83 of Std 802.11ax-2021. Equation 36-58 of IEEE P802.11be/D3.0
    if a==1 && isLDPC && ldpcExtraSymbol
        NSYMRX = NSYM-mSTBC;
    else
        NSYMRX = NSYM;
    end

    % Table 27-12 of IEEE P802.11be/D3.0. Table 36-18 of IEEE P802.11be/D3.0
    Nservice = 16;
    if isLDPC
        Ntail = 0;
    else
        Ntail = 6;
    end

    % Get the PSDU length, Equation 27-139, 27-143 of Std 802.11ax-2021.
    % Equation 36-112 of IEEE P802.11be/D3.0
    psduLengthBits = ((NSYMRX-mSTBC)*rdp.NDBPS+mSTBC*NDBPSLASTRX-Nservice-Ntail);

    % The number of pre-FEC padded bits added by the MAC will always be a multiple of eight
    NPADPreFECPHY = mod(psduLengthBits,8);
    NPADPreFECMAC = 0; % Assume PSDULength includes padding

    % Post FEC Padding
    NPADPostFEC = rdp.NCBPS-NCBPSLASTRX;

    userParams = struct;
    userParams.NSYM = NSYM;
    userParams.NSYMInit = NSYMinit;
    userParams.mSTBC = mSTBC;
    userParams.Rate = rdp.Rate;
    userParams.NBPSCS = rdp.NBPSCS;
    userParams.NSD = rdp.NSD;
    userParams.NCBPS = rdp.NCBPS;
    userParams.NDBPS = rdp.NDBPS;
    userParams.DCM = dcm;
    userParams.NSS = rdp.NSS;
    userParams.NCBPSSHORT = NCBPSSHORTRX;
    userParams.NDBPSSHORT = NDBPSSHORTRX;
    userParams.NCBPSLAST = NCBPSLASTRX;
    userParams.NCBPSLASTInit = NCBPSLASTinitRX;
    userParams.NDBPSLAST = NDBPSLASTRX;
    userParams.NDBPSLASTInit = NDBPSLASTinitRX;
    userParams.NPADPreFECMAC = NPADPreFECMAC;
    userParams.NPADPreFECPHY = NPADPreFECPHY;
    userParams.NPADPostFEC = NPADPostFEC;
    userParams.PreFECPaddingFactor = a;
    userParams.PreFECPaddingFactorInit = aInitcommon;
    userParams.LDPCExtraSymbol = ldpcExtraSymbol;
    userParams.PSDULength = floor(psduLengthBits/8); % Equation 27-143 of Std 802.11ax-2021. Equation 36-112 of IEEE P802.11be/D3.0

end
