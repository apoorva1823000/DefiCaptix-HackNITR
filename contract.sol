// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;
contract CrowdFunding{
    uint public constant ELECTRICITY_EMISSIONS_FACTOR = uint(9) / uint(10); // kgCO2/kWh
    uint public constant NATURAL_GAS_EMISSIONS_FACTOR = uint(2) / uint(10); // kgCO2/kWh
    uint public constant FUEL_EMISSIONS_FACTOR = uint(23) / uint(10);
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    struct CarbonFootprint {
        uint electricityUsage; // electricity usage in kWh
        uint naturalGasUsage; // natural gas usage in kWh
        uint fuelUsage; // fuel usage in liters
        uint totalEmissions; // total emissions in kgCO2
    }

    mapping(uint=>Request)public requests;
    uint public numRequests;

    constructor(){
        target = 1000;
        deadline = block.timestamp+3600;
        minimumContribution = 100 wei;
        manager = msg.sender;
        
    }
    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum contribution is not met");
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value; 
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    } 

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed==false,"The requirement for this request has met");
        require(thisRequest.noOfVoters> noOfContributors/2,"Unfortunately the majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;

    }

    function calculateCarbonFootprint(uint electricityUsage, uint naturalGasUsage, uint fuelUsage) public pure returns (CarbonFootprint memory) {
        CarbonFootprint memory footprint;
        footprint.electricityUsage = electricityUsage;
        footprint.naturalGasUsage = naturalGasUsage;
        footprint.fuelUsage = fuelUsage;
        footprint.totalEmissions = electricityUsage * ELECTRICITY_EMISSIONS_FACTOR + naturalGasUsage * NATURAL_GAS_EMISSIONS_FACTOR + fuelUsage * FUEL_EMISSIONS_FACTOR;
        return footprint;
    }

}