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
        string name;
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

    // https://www.unixtimestamp.com/ can be used to calculate start and end time 
    constructor (string memory _title, uint _start_time, uint _end_time, string[] memory _input_candidates, uint _voters_number){
        title = _title;
        owner = msg.sender;
        start_time = _start_time;
        end_time = _end_time;
        for(uint i = 0; i < _input_candidates.length ; i++){
            add_candidate(_input_candidates[i]);
        }
        insert_total_participants(_voters_number);
    }

    modifier validTime() { // to check if vote is still open based on start and end time
        require(
            block.timestamp >= start_time, 
            "Vote is not started yet!"
        );
        require(
            block.timestamp < end_time,
            "Voting time is over!"
        );
        _;
    }

    function add_candidate(string memory _name) private { 
        // add candidates names to the list > voters will choose their index for voting
        require(
            msg.sender == owner,
            "Only vote owner can add a candidate!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );
        candidates.push(candidate({
                name: _name,
                vote_counter: 0
            }));

    }

    function insert_total_participants(uint _total_num) private{ 
        // owner setting total number of voters
        require(
            msg.sender == owner,
            "Only vote owner can add a candidate!"
        );
        participant_number = _total_num;
    }

    function extend_vote(uint _new_time) public{ // expanding vote time by changing deadline
        require(
            msg.sender == owner,
            "Only vote owner can add a candidate!"
        );

        require(
            _new_time > end_time,
            "New time should be after existing end time!"
        );

        end_time=_new_time;

    }

    function add_single_voter(address _voter_wallet) public { // adding a single voter by its wallet address
        require(
            msg.sender == owner,
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

    function add_voter(address[] memory _new_voters) public { // adding multiple voters by an array of their addresses
        require(
            msg.sender == owner,
            "Only vote owner can add a candidate!"
        );
        require(
            !is_ended,
            "Vote is closed!"
        );


        for(uint i = 0 ; i < _new_voters.length ; i++){
            require (
            !voters[_new_voters[i]].has_voted,
            "one of selected voters has already voted"
            );
            

        }
        for(uint i = 0 ; i < _new_voters.length ; i++){
            voters[_new_voters[i]].permission = true;
            voters[_new_voters[i]].power++;

        }
        
    }

    function vote(uint _candidate_index) public validTime{ 
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
        candidates[_candidate_index].vote_counter+=voters[msg.sender].power;
        total_voted+=voters[msg.sender].power;

    }

    function close_vote() public {
        require(
            msg.sender == owner,
            "Only vote manager can close the vote!"
        );
        // not started
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
        );

        require(
            voters[_destination].permission,
            "Chosen destination dont have the permission to vote!"
        );

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

    function result() public view returns(string memory){
        require (
            is_ended,
            "Vote is still open!"
        );

        require(
            participant_number > 0,
            "Owner have to insert number of participants first!"
        );

        require(
            total_voted >= (participant_number/2),
            "Vote is not valid due to number of votes shortage!"
        );



        string memory _winner;
        uint _win_votes;
        bool _tie;

        for(uint i = 0 ; i < candidates.length ; i++){
            if( candidates[i].vote_counter > _win_votes){
                _tie = false;
                _win_votes = candidates[i].vote_counter;
                _winner = candidates[i].name;
            }else if( candidates[i].vote_counter == _win_votes){
                _tie = true;
            }
        }

        if(!_tie){
            return _winner;
        }else{
            return "There Is A Tie !";
        }
    }

    function compare_strings(string memory a, string memory b) private view returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function get_candidate_code (string memory _name) public view returns(uint){
        uint _candidate_code;
        bool found;
        for(uint i = 0 ; i < candidates.length ; i++){
            if(compare_strings(candidates[i].name,_name)){
                found = true;
                _candidate_code = i;
            }
        }
        require(
            found,
            "This candidate doesn't exists!"
        );
        return _candidate_code;
    }

    function find_time (uint _from_now) public view returns(uint){ 
        // returns a time in unix timestamp relative to currnet time ( based on days )
        require(
            msg.sender == owner,
            "Only owner can calculate time using this function"
        );
        uint date_unix_ = block.timestamp + (_from_now * 1 days);
        return date_unix_;

    }
}
