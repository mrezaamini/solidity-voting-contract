pragma solidity ^0.8.0;

contract voting{
    struct Voter{
        bool has_voted; // if voter has voted yet
        uint vote; // index of the selected candidate
        bool permission; // if they have the permission to vote 
        address alternate_voter; // address of the person who can vote instead of this voter
        uint power; // effectiveness of his vote in final result (can be increased by other people giving their vote to this voter)
    }
    struct candidate{
        bytes32 name;
        uint vote_counter;
    }
    address public owner;
    mapping (address => Voter) voters;
    uint participant_number;
    uint total_voted;
    candidate[] public candidates;
    bool is_ended;
    string public title;
    uint start_time;
    uint end_time;

    constructor (string memory _title){
        title = _title;
        owner = msg.sender;
    }

    function add_candidate(string _name) public {
        require(
            msg.sender = owner,
            "Only vote owner can add a candidate!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );
        candidates.push(candidate(_name, 0));

    }

    function insert_total_participants(uint _total_num) public{
        require(
            msg.sender = owner,
            "Only vote owner can add a candidate!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );
        participant_number = _total_num;
    }

    function extend_vote(uint _new_time){
        require(
            msg.sender = owner,
            "Only vote owner can add a candidate!"
        );

        require(
            _new_time > end_time,
            "New time should be after existing end time!"
        );

        end_time=_new_time;

    }

    function add_voter(address _voter_wallet) public {
        require(
            msg.sender = owner,
            "Only vote owner can add a candidate!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );
        require (
            !voters[_voter_wallet].has_voted,
            "This voter already voted"
        );
        voters[_voter_wallet].permission = true;
        voters[_voter_wallet].power++;
    }

    function vote(uint _candidate_index) public{
        require(
            !voters[msg.sender].has_voted,
            "This voter already voted!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );
        require (
            voters[msg.sender].permission,
            "This voter doesn't have the permission to vote!"
        );

        voters[msg.sender].vote = _candidate_index;
        voters[msg.sender].has_voted = true;
        candidates[_candidate_index].vote_counter++;
        total_voted++;

    }

    function close_vote() public {
        require(
            msg.sender == owner,
            "Only vote manager can close the vote!"
        );
        is_ended=true;
    }

    function send_permission(address _destination) public { // send voting permission to another person
        require(
            !voters[msg.sender].has_voted,
            "You voted already!"
        );

        require(
            !is_ended,
            "Vote is ended!"
        )

        require(
            _destination != msg.sender, 
            "Can not give yourself the permission!"
        );

        while (voters[_destination].alternate_voter != address(0)) { 
            // to iterate all alternative voters one by one to reach
            //the final person who is really going to have the persmission to vote
            _destination = voters[_destination].alternate_voter;
            require(
            _destination != msg.sender,
            "Permission is going back to you!"
            );
        }
        voters[msg.sender].has_voted = true; 
        voters[msg.sender].alternate_voter = _destination;
        if (voters[_destination].has_voted) { // if new voter already voted >> number of last voter votes will be added to chosen candidate
            candidates[voters[_destination].vote].vote_counter += voters[msg.sender].power;
        } else { // if not, new voter have sum of his own and last persons vote power.
            voters[_destination].power += voters[msg.sender].power;
        }
    }
    

}

// TODO: array of voters input / intial permission? / permission to another person who has not have the permision (delegate)