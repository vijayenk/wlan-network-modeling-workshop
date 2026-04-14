function allocStruct = heRUAllocationLUT(assignment)
%heRUAllocationLUT HE RU allocation details
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   ALLOCSTRUCT = heRUAllocationLUT(ASSIGNMENT) returns a structure
%   containing the RU allocation given the assignment index as per IEEE
%   Std 802.11ax-2021, Table 27-26.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

allocStruct = struct('NumRUs',0,'NumUsers',0,'RUSizes',0,'RUIndices',0,'NumUsersPerRU',0);

switch assignment
    case 0
        allocStruct.NumRUs = 9;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 2 3 4 5 6 7 8 9 ];
        allocStruct.RUSizes = [26 26 26 26 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 1 ];
    case 1
        allocStruct.NumRUs = 8;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 3 4 5 6 7 4 ];
        allocStruct.RUSizes = [26 26 26 26 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 ];
    case 2
        allocStruct.NumRUs = 8;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 3 4 5 3 8 9 ];
        allocStruct.RUSizes = [26 26 26 26 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 ];
    case 3
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 3 4 5 3 4 ];
        allocStruct.RUSizes = [26 26 26 26 26 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 4
        allocStruct.NumRUs = 8;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 2 5 6 7 8 9 ];
        allocStruct.RUSizes = [26 26 52 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 ];
    case 5
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 2 5 6 7 4 ];
        allocStruct.RUSizes = [26 26 52 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 6
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 2 5 3 8 9 ];
        allocStruct.RUSizes = [26 26 52 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 7
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 2 5 3 4 ];
        allocStruct.RUSizes = [26 26 52 26 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 8
        allocStruct.NumRUs = 8;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 3 4 5 6 7 8 9 ];
        allocStruct.RUSizes = [52 26 26 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 ];
    case 9
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 3 4 5 6 7 4 ];
        allocStruct.RUSizes = [52 26 26 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 10
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 3 4 5 3 8 9 ];
        allocStruct.RUSizes = [52 26 26 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 11
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 3 4 5 3 4 ];
        allocStruct.RUSizes = [52 26 26 26 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 12
        allocStruct.NumRUs = 7;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 5 6 7 8 9 ];
        allocStruct.RUSizes = [52 52 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 ];
    case 13
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 5 6 7 4 ];
        allocStruct.RUSizes = [52 52 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 14
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 5 3 8 9 ];
        allocStruct.RUSizes = [52 52 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 15
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 5 3 4 ];
        allocStruct.RUSizes = [52 52 26 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 ];
    case 16
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 ];
    case 17
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 2 ];
    case 18
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 3 ];
    case 19
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 4 ];
    case 20
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 5 ];
    case 21
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 6 ];
    case 22
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 7 ];
    case 23
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 2 2 ];
        allocStruct.RUSizes = [52 52 106 ];
        allocStruct.NumUsersPerRU = [1 1 8 ];
    case 24
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 ];
    case 25
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [2 1 1 ];
    case 26
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [3 1 1 ];
    case 27
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [4 1 1 ];
    case 28
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [5 1 1 ];
    case 29
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [6 1 1 ];
    case 30
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [7 1 1 ];
    case 31
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 3 4 ];
        allocStruct.RUSizes = [106 52 52 ];
        allocStruct.NumUsersPerRU = [8 1 1 ];
    case 32
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 33
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 2 ];
    case 34
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 3 ];
    case 35
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 4 ];
    case 36
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 5 ];
    case 37
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 6 ];
    case 38
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 7 ];
    case 39
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 2 3 4 5 2 ];
        allocStruct.RUSizes = [26 26 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 8 ];
    case 40
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 ];
    case 41
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 2 ];
    case 42
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 3 ];
    case 43
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 4 ];
    case 44
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 5 ];
    case 45
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 6 ];
    case 46
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 7 ];
    case 47
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 2 2 5 2 ];
        allocStruct.RUSizes = [26 26 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 8 ];
    case 48
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 ];
    case 49
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 2 ];
    case 50
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 3 ];
    case 51
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 4 ];
    case 52
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 5 ];
    case 53
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 6 ];
    case 54
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 7 ];
    case 55
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 3 4 5 2 ];
        allocStruct.RUSizes = [52 26 26 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 8 ];
    case 56
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 ];
    case 57
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 2 ];
    case 58
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 3 ];
    case 59
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 4 ];
    case 60
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 5 ];
    case 61
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 6 ];
    case 62
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 7 ];
    case 63
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 2 5 2 ];
        allocStruct.RUSizes = [52 52 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 8 ];
    case 64
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 1 ];
    case 65
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [2 1 1 1 1 1 ];
    case 66
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [3 1 1 1 1 1 ];
    case 67
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [4 1 1 1 1 1 ];
    case 68
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [5 1 1 1 1 1 ];
    case 69
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [6 1 1 1 1 1 ];
    case 70
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [7 1 1 1 1 1 ];
    case 71
        allocStruct.NumRUs = 6;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 6 7 8 9 ];
        allocStruct.RUSizes = [106 26 26 26 26 26 ];
        allocStruct.NumUsersPerRU = [8 1 1 1 1 1 ];
    case 72
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 ];
    case 73
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [2 1 1 1 1 ];
    case 74
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [3 1 1 1 1 ];
    case 75
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [4 1 1 1 1 ];
    case 76
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [5 1 1 1 1 ];
    case 77
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [6 1 1 1 1 ];
    case 78
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [7 1 1 1 1 ];
    case 79
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 6 7 4 ];
        allocStruct.RUSizes = [106 26 26 26 52 ];
        allocStruct.NumUsersPerRU = [8 1 1 1 1 ];
    case 80
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 1 ];
    case 81
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [2 1 1 1 1 ];
    case 82
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [3 1 1 1 1 ];
    case 83
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [4 1 1 1 1 ];
    case 84
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [5 1 1 1 1 ];
    case 85
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [6 1 1 1 1 ];
    case 86
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [7 1 1 1 1 ];
    case 87
        allocStruct.NumRUs = 5;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 3 8 9 ];
        allocStruct.RUSizes = [106 26 52 26 26 ];
        allocStruct.NumUsersPerRU = [8 1 1 1 1 ];
    case 88
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 ];
    case 89
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [2 1 1 1 ];
    case 90
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [3 1 1 1 ];
    case 91
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [4 1 1 1 ];
    case 92
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [5 1 1 1 ];
    case 93
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [6 1 1 1 ];
    case 94
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [7 1 1 1 ];
    case 95
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 3 4 ];
        allocStruct.RUSizes = [106 26 52 52 ];
        allocStruct.NumUsersPerRU = [8 1 1 1 ];
    case 96
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 2;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [1 1 ];
    case 97
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [1 2 ];
    case 98
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [1 3 ];
    case 99
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [1 4 ];
    case 100
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [2 1 ];
    case 101
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [2 2 ];
    case 102
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [2 3 ];
    case 103
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [2 4 ];
    case 104
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [3 1 ];
    case 105
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [3 2 ];
    case 106
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [3 3 ];
    case 107
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [3 4 ];
    case 108
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [4 1 ];
    case 109
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [4 2 ];
    case 110
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [4 3 ];
    case 111
        allocStruct.NumRUs = 2;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 2 ];
        allocStruct.RUSizes = [106 106 ];
        allocStruct.NumUsersPerRU = [4 4 ];
    case 112
        allocStruct.NumRUs = 4;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 2 3 4 ];
        allocStruct.RUSizes = [52 52 52 52 ];
        allocStruct.NumUsersPerRU = [1 1 1 1 ];
    case 113
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 0;
    case 114
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 0;
    case 115
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 0;
    case 116
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 117
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 118
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 119
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 120
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 121
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 122
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 123
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 124
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 125
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 126
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 127
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 128
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 1 ];
    case 129
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 2 ];
    case 130
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 3 ];
    case 131
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 4 ];
    case 132
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 5 ];
    case 133
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 6 ];
    case 134
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 7 ];
    case 135
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [1 1 8 ];
    case 136
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 1 ];
    case 137
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 2 ];
    case 138
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 3 ];
    case 139
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 4 ];
    case 140
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 5 ];
    case 141
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 6 ];
    case 142
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 7 ];
    case 143
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [2 1 8 ];
    case 144
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 1 ];
    case 145
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 2 ];
    case 146
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 3 ];
    case 147
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 4 ];
    case 148
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 5 ];
    case 149
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 6 ];
    case 150
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 7 ];
    case 151
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [3 1 8 ];
    case 152
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 1 ];
    case 153
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 2 ];
    case 154
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 3 ];
    case 155
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 4 ];
    case 156
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 5 ];
    case 157
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 6 ];
    case 158
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 7 ];
    case 159
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [4 1 8 ];
    case 160
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 1 ];
    case 161
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 2 ];
    case 162
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 3 ];
    case 163
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 4 ];
    case 164
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 5 ];
    case 165
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 6 ];
    case 166
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 7 ];
    case 167
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 14;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [5 1 8 ];
    case 168
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 1 ];
    case 169
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 2 ];
    case 170
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 3 ];
    case 171
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 4 ];
    case 172
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 5 ];
    case 173
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 6 ];
    case 174
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 14;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 7 ];
    case 175
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 15;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [6 1 8 ];
    case 176
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 9;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 1 ];
    case 177
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 2 ];
    case 178
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 3 ];
    case 179
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 4 ];
    case 180
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 5 ];
    case 181
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 14;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 6 ];
    case 182
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 15;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 7 ];
    case 183
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 16;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [7 1 8 ];
    case 184
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 10;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 1 ];
    case 185
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 11;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 2 ];
    case 186
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 12;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 3 ];
    case 187
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 13;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 4 ];
    case 188
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 14;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 5 ];
    case 189
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 15;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 6 ];
    case 190
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 16;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 7 ];
    case 191
        allocStruct.NumRUs = 3;
        allocStruct.NumUsers = 17;
        allocStruct.RUIndices = [1 5 2 ];
        allocStruct.RUSizes = [106 26 106 ];
        allocStruct.NumUsersPerRU = [8 1 8 ];
    case 192
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 1;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 1;
    case 193
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 2;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 2;
    case 194
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 3;
    case 195
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 4;
    case 196
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 5;
    case 197
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 6;
    case 198
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 7;
    case 199
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.NumUsersPerRU = 8;
    case 200
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 1;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 1;
    case 201
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 2;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 2;
    case 202
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 3;
    case 203
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 4;
    case 204
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 5;
    case 205
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 6;
    case 206
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 7;
    case 207
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.NumUsersPerRU = 8;
    case 208
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 1;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 1;
    case 209
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 2;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 2;
    case 210
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 3;
    case 211
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 4;
    case 212
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 5;
    case 213
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 6;
    case 214
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 7;
    case 215
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 996;
        allocStruct.NumUsersPerRU = 8;
    case 216
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 1;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 1;
    case 217
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 2;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 2;
    case 218
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 3;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 3;
    case 219
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 4;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 4;
    case 220
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 5;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 5;
    case 221
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 6;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 6;
    case 222
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 7;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 7;
    case 223
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = 8;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 1992;
        allocStruct.NumUsersPerRU = 8;
    case 224
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 225
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 226
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 227
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 228
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 229
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 230
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 231
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 232
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 233
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 234
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 235
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 236
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 237
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 238
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 239
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 240
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 241
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 242
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 243
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 244
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 245
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 246
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 247
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 248
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 249
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 250
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 251
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 252
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 253
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    case 254
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
    otherwise % 255
        allocStruct.NumRUs = 0;
        allocStruct.NumUsers = 0;
        allocStruct.RUIndices = 0;
        allocStruct.RUSizes = 0;
        allocStruct.NumUsersPerRU = 0;
end
end
