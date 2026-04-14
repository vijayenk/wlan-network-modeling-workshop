classdef PHYPrimitives
%PHYPrimitives Indicate the values for PHY indications between the PHY and
%the MAC layer
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   PRMTVE = PHYPrimitives creates an object with the all the supported PHY
%   primitive constant values. All the supported values are mentioned
%   below. PHY SAP service primitive parameters are defined in Table 8-3 of
%   IEEE Std 802.11-2020.
%
%   PHYPrimitives properties:
%
%   CCAIndication(1)      - CCAindication
%   RxStartIndication(2)  - Rx start indication
%   RxEndIndication(3)    - Rx end indication
%   RxErrorIndication(4)  - Rx error indication
%   TxStartRequest(5)     - Tx start request
%   UnknownIndication(0)  - Unknown indication

%   Copyright 2022-2025 The MathWorks, Inc.

properties (Constant)
    % CCA indication
    CCAIndication = 1
    % Rx start indication
    RxStartIndication = 2
    % Rx end indication
    RxEndIndication = 3
    % Rx error indication
    RxErrorIndication = 4
    % Tx start request
    TxStartRequest = 5
    % Unknown / invalid indication
    UnknownIndication = 0
end
end
