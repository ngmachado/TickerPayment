pragma solidity >=0.6.0 <0.7.0;

import "./IERC20.sol";
/*
    Timer Payment with DAI Token.

    Set a payment channel with someone, this contract will check your configuration to make the transaction.
    *** DONT SEND TOKENS OR ETHER TO THIS CONTRACT ***
    The user should approve this contract address to make payments.
    This contract don't validate balances, it only check the block height and call 'transferFrom' at DAI contract.

    Atention: The counter index is important be submitted in order, each index invalided the lower indexes.
*/
contract Ticker {

    IERC20 public DAI;

    struct Autorization {
        uint256 blocknumber;
        uint256 interval;
        uint256 numberTicks;
        uint256 intervalPayment;
        uint256 counter;
    }

    mapping(address => mapping(address => Autorization)) public register;

    event SetPayment(address to, uint256 interval, uint256 intervalPayment, uint256 numberTicks);
    event Payment(address from, address to, uint256 amount, uint256 limitIndex);

    constructor() public {
        DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function setPayment(address _to, uint256 _interval, uint256 _numberTicks, uint256 _intervalPayment) external {

        register[msg.sender][_to] = Autorization(block.number, _interval, _numberTicks, _intervalPayment, 0);
        emit SetPayment(_to, _interval, _intervalPayment, _numberTicks);
    }

    function receivePayment(address _from, uint256 _untilIndex) public {

        Autorization storage _auth = register[_from][msg.sender];
        uint256 _diff = (block.number - _auth.blocknumber + _auth.counter) / _auth.interval;

        require(_auth.counter < _untilIndex, 'not order index');
        _auth.counter = _untilIndex;

        emit Payment(_from, msg.sender, _diff * _auth.intervalPayment, _auth.counter);

        DAI.transferFrom(_from, msg.sender, _diff * _auth.intervalPayment);
    }

    function revoke(address _from, address _to) public {

        if(msg.sender == _from) {
            delete register[msg.sender][_to];
        } else if(msg.sender == _to) {
            delete register[_from][msg.sender];
        } else {
            revert();
        }
    }
}
