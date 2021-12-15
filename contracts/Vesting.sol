pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Vesting is Context, Ownable {
  IERC20 internal _token;
  uint256 _daysOfLock;
  uint256 _start;
  uint256 _end;
  bool _isFinal;
  uint256 _totalVested;
  mapping(address => uint256) _vested;

  event Started(uint256 _startTime);
  event Extended(uint256 _newEndTime);

  struct Vest {
    address _address;
    uint256 _amount;
  }

  constructor(address token_, uint256 daysOfLock_) {
    _token = IERC20(token_);
    _daysOfLock = (daysOfLock_ * 1 days);
  }

  /** @dev Start vesting countdown
   */
  function startVest(uint256 _daysBeforeStart, uint256 _daysToLast)
    external
    onlyOwner
    returns (bool)
  {
    require(_daysBeforeStart > 0, 'days before start cannot be 0');
    require(_daysToLast > 0, 'days to last cannot be 0');
    _start = block.timestamp + (_daysBeforeStart * 1 days);
    _end = _start + (_daysToLast * 1 days);
    emit Started(block.timestamp);
    return true;
  }

  function endVest() external onlyOwner {
    _end = block.timestamp;
  }

  function extendVesting(uint256 _daysToExtendBy) external onlyOwner {
    require(!_isFinal, 'vesting has been finalized');
    if (_end <= block.timestamp)
      _end = block.timestamp + (_daysToExtendBy * 1 days);
    else _end = _end + (_daysToExtendBy * 1 days);

    emit Extended(_end);
  }

  function finalizeVesting() external onlyOwner {
    _isFinal = true;
  }

  function vest(Vest[] calldata _vests) external onlyOwner {
    uint256 _sum;

    for (uint256 i = 0; i < _vests.length; i++) _sum = _sum + _vests[i]._amount;

    require(
      (_sum + _totalVested) <= _token.balanceOf(address(this)),
      'not enough tokens'
    );

    for (uint256 i = 0; i < _vests.length; i++)
      _vested[_vests[i]._address] =
        _vested[_vests[i]._address] +
        _vests[i]._amount;

    _totalVested = _totalVested + _sum;
  }
}
