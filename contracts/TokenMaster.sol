// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenMaster is ERC721, ReentrancyGuard {
    address public owner;
    uint256 public totalOccasions;
    uint256 public totalSupply;

    enum OccasionStatus { Active, Cancelled, Completed }

    struct Occasion {
        uint256 id;
        string name;
        uint256 cost;
        uint256 tickets;
        uint256 maxTickets;
        string date;
        string time;
        string location;
        OccasionStatus status;
    }

    mapping(uint256 => Occasion) public occasions;
    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(uint256 => mapping(uint256 => address)) public seatTaken;
    mapping(uint256 => uint256[]) public seatsTaken;

    event OccasionCreated(uint256 indexed occasionId, string name, uint256 cost, uint256 maxTickets);
    event TicketMinted(uint256 indexed occasionId, uint256 seat, address indexed buyer);
    event Withdrawal(address indexed owner, uint256 amount);
    event OccasionCancelled(uint256 indexed occasionId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        owner = msg.sender;
    }

    function list(
        string memory _name,
        uint256 _cost,
        uint256 _maxTickets,
        string memory _date,
        string memory _time,
        string memory _location
    ) public onlyOwner {
        totalOccasions++;
        occasions[totalOccasions] = Occasion(
            totalOccasions,
            _name,
            _cost,
            _maxTickets,
            _maxTickets,
            _date,
            _time,
            _location,
            OccasionStatus.Active
        );

        emit OccasionCreated(totalOccasions, _name, _cost, _maxTickets);
    }

    function mint(uint256 _id, uint256 _seat) public payable nonReentrant {
        require(_id > 0 && _id <= totalOccasions, "Invalid occasion ID");
        require(msg.value >= occasions[_id].cost, "Insufficient ETH sent");
        require(seatTaken[_id][_seat] == address(0), "Seat already taken");
        require(_seat > 0 && _seat <= occasions[_id].maxTickets, "Invalid seat number");
        require(occasions[_id].status == OccasionStatus.Active, "Occasion not active");

        occasions[_id].tickets -= 1;
        hasBought[_id][msg.sender] = true;
        seatTaken[_id][_seat] = msg.sender;
        seatsTaken[_id].push(_seat);

        totalSupply++;

        _safeMint(msg.sender, totalSupply);

        emit TicketMinted(_id, _seat, msg.sender);
    }

    function getOccasion(uint256 _id) public view returns (Occasion memory) {
        return occasions[_id];
    }

    function getSeatsTaken(uint256 _id) public view returns (uint256[] memory) {
        return seatsTaken[_id];
    }

    function cancelOccasion(uint256 _id) public onlyOwner {
        require(_id > 0 && _id <= totalOccasions, "Invalid occasion ID");
        require(occasions[_id].status == OccasionStatus.Active, "Occasion not active");

        occasions[_id].status = OccasionStatus.Cancelled;

        emit OccasionCancelled(_id);
    }

    function refund(uint256 _id) public nonReentrant {
        require(_id > 0 && _id <= totalOccasions, "Invalid occasion ID");
        require(occasions[_id].status == OccasionStatus.Cancelled, "Occasion not cancelled");
        require(hasBought[_id][msg.sender], "No ticket purchased");

        uint256 seat;
        for (uint256 i = 0; i < seatsTaken[_id].length; i++) {
            if (seatTaken[_id][seatsTaken[_id][i]] == msg.sender) {
                seat = seatsTaken[_id][i];
                break;
            }
        }

        require(seat != 0, "Seat not found");

        hasBought[_id][msg.sender] = false;
        seatTaken[_id][seat] = address(0);

        (bool success, ) = msg.sender.call{value: occasions[_id].cost}("");
        require(success, "Refund failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(owner, balance);
    }
}
