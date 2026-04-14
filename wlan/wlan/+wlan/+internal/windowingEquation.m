function [index,mag] = windowingEquation(tranisitionLength,symLength)
%windowingEquation Generate index and magnitude of OFDM windowing function
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [INDEX,MAG] = windowingEquation(TRANISITIONLENGTH,SYMLENGTH) generates
%   the windowing indices and magnitudes for OFDM symbols. INDEX and MAG
%   are the indices and respective magnitudes of the windowing function.
%
%   TRANISITIONLENGTH is the length of the overlap windowing region in
%   samples used to smooth the transitions between consecutive OFDM
%   symbols.
%
%   SYMLENGTH is the length of the OFDM symbol.
%
%   See also windowSymbol

%   Copyright 2016 The MathWorks, Inc.

%#codegen
  
% The windowing function for the OFDM symbols is defined in IEEE Std
% 802.11ad-2012, Section 21.3.5.2.

TTR = tranisitionLength;
preIdx = -TTR/2+1:TTR/2-1;
midIdx = TTR/2:(symLength-TTR/2)-1;
postIdx = symLength-TTR/2:(symLength+TTR/2)-1;
index = [preIdx midIdx postIdx].'; 
preMag = sin(pi/2*(0.5+(preIdx)/(TTR))).^2;
midMag = ones(1,length(midIdx)); 
postMag = sin(pi/2*(0.5-((postIdx)-symLength)/TTR)).^2; 
mag = [preMag midMag postMag].';

end