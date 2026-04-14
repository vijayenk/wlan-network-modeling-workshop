function r = heRUAllocationTable()
%heRUAllocationTable HE RU allocation details
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   R = heRUAllocationTable() returns a table of RU allocations as per IEEE
%   Std 802.11ax-2021, Table 27-26. Each row of the table is a resource unit
%   (RU) allocation. The columns contain information about each allocation
%   including the number of users, number of RUs and the RU sizes and
%   indices.

%   Copyright 2022-2023 The MathWorks, Inc.

persistent allocationTable
persistent allocations

if isempty(allocationTable) || isempty(allocations)

    offset = 0;

    HEAllocation = struct('Allocation',0,'BitAllocation',"00000000",'NumUsers',0,'NumRUs',0,'RUIndices',[],'RUSizes',[],'NumUsersPerRU',[],'Note',"");
    allocations = HEAllocation;

    numAllocations = 16;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;
        allocation.Allocation = i+offset;
        t =  int2bit(i,4).';
        num26RUsAllocated = 0;
        for it = 1:4
            if t(it)==0
                allocation.RUSizes = [allocation.RUSizes 26*ones(1,2)];
                allocation.RUIndices = [allocation.RUIndices num26RUsAllocated+(1:2)];
                num26RUsAllocated = num26RUsAllocated+2;
            else
                allocation.RUSizes = [allocation.RUSizes 52];
                allocation.RUIndices = [allocation.RUIndices ceil((num26RUsAllocated+1)/2)];
                num26RUsAllocated = num26RUsAllocated+2;
            end
            if it==2
                allocation.RUSizes = [allocation.RUSizes 26];
                allocation.RUIndices = [allocation.RUIndices num26RUsAllocated+(1)];
                num26RUsAllocated = num26RUsAllocated+1;
            end
        end
        allocation.NumUsersPerRU = ones(size(allocation.RUSizes));
        allocation.NumRUs = numel(allocation.RUSizes);
        allocation.NumUsers = allocation.NumRUs;
        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;
        allocation.Allocation = i+offset;
        allocation.RUSizes = [52 52 106];
        allocation.RUIndices = [1 2 2];
        allocation.NumUsersPerRU = [1 1 i+1];
        allocation.NumRUs = numel(allocation.RUSizes);
        allocation.NumUsers = 2+1+i;
        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;
        allocation.Allocation = i+offset;
        allocation.RUSizes = [106 52 52];
        allocation.RUIndices = [1 3 4];
        allocation.NumUsersPerRU = [i+1 1 1];
        allocation.NumRUs = numel(allocation.RUSizes);
        allocation.NumUsers = 2+1+i;
        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 32;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;
        allocation.Allocation = i+offset;
        t = int2bit(floor(i/8),2).';
        num26RUsAllocated = 0;
        for it = 1:2
            if t(it)==0
                allocation.RUSizes = [allocation.RUSizes 26*ones(1,2)];
                allocation.RUIndices = [allocation.RUIndices num26RUsAllocated+(1:2)];
                num26RUsAllocated = num26RUsAllocated+2;
            else
                allocation.RUSizes = [allocation.RUSizes 52];
                allocation.RUIndices = [allocation.RUIndices ceil((num26RUsAllocated+1)/2)];
                num26RUsAllocated = num26RUsAllocated+2;
            end
        end
        allocation.RUSizes = [allocation.RUSizes 26 106];
        allocation.RUIndices = [allocation.RUIndices 5 2];


        allocation.NumUsersPerRU = ones(size(allocation.RUSizes));
        allocation.NumUsersPerRU(end) = allocation.NumUsersPerRU(end)+mod(i,8);
        allocation.NumRUs = numel(allocation.RUSizes);
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 32;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;
        allocation.Allocation = i+offset;

        allocation.RUSizes = [106 26];
        allocation.RUIndices = [1 5];

        t = int2bit(floor(i/8),2).';
        num26RUsAllocated = 5;
        for it = 1:2
            if t(it)==0
                allocation.RUSizes = [allocation.RUSizes 26*ones(1,2)];
                allocation.RUIndices = [allocation.RUIndices num26RUsAllocated+(1:2)];
                num26RUsAllocated = num26RUsAllocated+2;
            else
                allocation.RUSizes = [allocation.RUSizes 52];
                allocation.RUIndices = [allocation.RUIndices ceil((num26RUsAllocated+1)/2)];
                num26RUsAllocated = num26RUsAllocated+2;
            end
        end   

        allocation.NumUsersPerRU = ones(size(allocation.RUSizes));
        allocation.NumUsersPerRU(1) = allocation.NumUsersPerRU(1)+mod(i,8);
        allocation.NumRUs = numel(allocation.RUSizes);
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 16;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = [106 106];
        allocation.RUIndices = [1 2];
        allocation.NumUsersPerRU = [floor(i/4)+1 mod(i,4)+1]; % Y1Y0 Z1Z0
        allocation.NumRUs = 2;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 1;
    allocation = HEAllocation;
    allocation.Allocation = offset;
    allocation.RUSizes = [52 52 52 52];
    allocation.RUIndices = [1 2 3 4];
    allocation.NumUsersPerRU = [1 1 1 1];
    allocation.NumRUs = numel(allocation.RUSizes);
    allocation.NumUsers = sum(allocation.NumUsersPerRU);
    allocations(1+offset) = allocation;
    offset = offset+numAllocations;

    % Empty 242-tone RU (113)
    numAllocations = 1;
    allocation = HEAllocation;
    allocation.Allocation = offset;
    allocation.RUSizes = 242;
    allocation.RUIndices = 1;
    allocation.NumUsersPerRU = 0;
    allocation.NumRUs = 0;
    allocation.NumUsers = 0;
    allocation.Note = "Empty";
    allocations(1+offset) = allocation;
    offset = offset+numAllocations;

    % 484-tone RU with zero user-specific SIGB-contents
    numAllocations = 1;
    allocation = HEAllocation;
    allocation.Allocation = offset;
    allocation.RUSizes = 484;
    allocation.RUIndices = 1;
    allocation.NumUsersPerRU = 0;
    allocation.NumRUs = numel(allocation.RUSizes);
    allocation.NumUsers = sum(allocation.NumUsersPerRU);
    allocation.Note = "Zero HE-SIG-B User Specific field";
    allocations(1+offset) = allocation;
    offset = offset+numAllocations;

    % 996-tone RU with zero user-specific SIGB-contents
    numAllocations = 1;
    allocation = HEAllocation;
    allocation.Allocation = offset;
    allocation.RUSizes = 996;
    allocation.RUIndices = 1;
    allocation.NumUsersPerRU = 0;
    allocation.NumRUs = numel(allocation.RUSizes);
    allocation.NumUsers = sum(allocation.NumUsersPerRU);
    allocation.Note = "Zero HE-SIG-B User Specific field";
    allocations(1+offset) = allocation;
    offset = offset+numAllocations;

    % Reserved allocations
    numAllocations = 12;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 0;
        allocation.RUIndices = 0;
        allocation.NumUsersPerRU = 0;
        allocation.NumRUs = 0;
        allocation.NumUsers = 0;
        allocation.Note = "Reserved";

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    numAllocations = 64;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = [106 26 106];
        allocation.RUIndices = [1 5 2];
        allocation.NumUsersPerRU = [floor(i/8)+1 1 mod(i,8)+1]; % Y2Y1Y0 Z2Z1Z0
        allocation.NumRUs = 3;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % 242
    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 242;
        allocation.RUIndices = 1;
        allocation.NumUsersPerRU = i+1;
        allocation.NumRUs = 1;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % 484
    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 484;
        allocation.RUIndices = 1;
        allocation.NumUsersPerRU = i+1;
        allocation.NumRUs = 1;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % 996
    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 996;
        allocation.RUIndices = 1;
        allocation.NumUsersPerRU = i+1;
        allocation.NumRUs = 1;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % 2*996
    numAllocations = 8;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 2*996;
        allocation.RUIndices = 1;
        allocation.NumUsersPerRU = i+1;
        allocation.NumRUs = 1;
        allocation.NumUsers = sum(allocation.NumUsersPerRU);

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % Reserved allocations
    numAllocations = 32;
    for i = 0:(numAllocations-1)
        allocation = HEAllocation;

        allocation.Allocation = i+offset;
        allocation.RUSizes = 0;
        allocation.RUIndices = 0;
        allocation.NumUsersPerRU = 0;
        allocation.NumRUs = 0;
        allocation.NumUsers = 0;
        allocation.Note = "Reserved";

        allocations(i+1+offset) = allocation;
    end
    offset = offset+numAllocations;

    % Populate bit allocation
    for i = 1:offset
        allocations(i).BitAllocation = regexprep(string(num2str(int2bit(allocations(i).Allocation,8).')),' ','');
    end

    %  Create a table
    allocationTable = struct2table(allocations);
    r = allocationTable;
else
    r = allocationTable;
end

end
