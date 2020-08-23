pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface YieldPool {
  function balanceOf(address) external view returns (uint);
  function deposit(uint) external returns (uint);
  function withdraw(uint, address) external returns (uint);
}

interface RegistryInterface {
  function signer(address) external view returns (bool);
  function chief(address) external view returns (bool);
  function poolToken(address) external view returns (address);
}

contract Flusher {
  using SafeERC20 for IERC20; 

  address payable public owner;
  RegistryInterface public constant registry = RegistryInterface(address(0)); // TODO
  bool public shield;
  uint256 public shieldTime;

  modifier isSigner {
    require(registry.signer(msg.sender), "not-signer");
    _;
  }

  event LogInit(address indexed owner);

  event LogDeposit(
    address indexed caller,
    address indexed token,
    address indexed tokenPool,
    uint amount
  );

  event LogWithdraw(
    address indexed caller,
    address indexed token,
    address indexed tokenPool,
    uint amount
  );

  event LogWithdrawToOwner(
    address indexed caller,
    address indexed token,
    address indexed owner,
    uint amount
  );

  function deposit(address token) public isSigner {
    require(address(token) != address(0), "invalid-token");

    address poolToken = registry.poolToken(token);
    IERC20 tokenContract = IERC20(token);
    
    if (poolToken != address(0)) {
      YieldPool poolContract = YieldPool(poolToken);
      uint amt;
      if (address(tokenContract) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
        amt = address(this).balance;
        payable(poolToken).transfer(amt);
      } else {
        amt = tokenContract.balanceOf(address(this));
        if (tokenContract.allowance(address(this), address(poolContract)) == 0)
          tokenContract.approve(address(poolContract), uint(-1));

        poolContract.deposit(amt);
      }
      emit LogDeposit(msg.sender, token, address(poolContract), amt);
    } else {
      // TODO - check;
      uint amt = tokenContract.balanceOf(address(this));
      tokenContract.safeTransfer(owner, amt);
      emit LogWithdrawToOwner(msg.sender, token, owner, amt);

    }
  }

  function withdraw(address token, uint amount) external isSigner returns (uint) {
    require(address(token) != address(0), "invalid-token");
    address poolToken = registry.poolToken(token);
    
    if (poolToken != address(0)) {
      YieldPool poolContract = YieldPool(poolToken);
      uint poolBalance = poolContract.balanceOf(address(this));
      if (amount > poolBalance) amount = poolBalance;
      return poolContract.withdraw(amount, owner);
    } else {
      // TODO - check
      IERC20 tokenContract = IERC20(token);
      uint amt = tokenContract.balanceOf(address(this));
      tokenContract.safeTransfer(owner, amt);
      emit LogWithdraw(msg.sender, token, poolToken, amt); // TODO: why this event is not above statement when "if" is true
    }
  }

  /**
   * @dev withdraw to owner (rare case, used as backdoor)
   */
  function withdrawToOwner(address token) external isSigner returns (uint) {
    require(address(token) != address(0), "invalid-token");
    
    uint amt;
    if (address(token) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
      amt = address(this).balance;
      payable(owner).transfer(amt);
    } else {
      IERC20 tokenContract = IERC20(token);
      amt = tokenContract.balanceOf(address(this));
      tokenContract.safeTransfer(address(owner), amt);
    }
    emit LogWithdrawToOwner(msg.sender, token, owner, amt);
  }

  function setBasic(address newOwner, address token) external {
    owner = payable(newOwner);
    deposit(token);
    emit LogInit(newOwner);
  }

  function switchShield() external {
    require(registry.chief(msg.sender), "not-chief");
    shield = !shield;
    if (!shield) {
      shieldTime = now + 90 days;
    } else {
      delete shieldTime;
    }
    // TODO: emit event so we can keep a track of this contract on backend of any other suggestions?
  }

  /**
   * @dev backdoor function
   */
  function spell(address _target, bytes calldata _data) external {
    require(!shield, "shield-access-denied");
    require(shieldTime != 0 && shieldTime <= now, "less-than-ninty-days");
    require(_target != address(0), "target-invalid");
    require(_data.length > 0, "data-invalid"); // TODO: Is the data array?
    bytes memory _callData = _data;
    address _owner = owner;
    assembly {
      let succeeded := delegatecall(gas(), _target, add(_callData, 0x20), mload(_callData), 0, 0)
      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        let size := returndatasize()
        returndatacopy(0x00, 0x00, size)
        revert(0x00, size)
      }
    }
    require(_owner == owner, "owner-change-denied");
    // TODO: emit event so we can keep a track of this contract on backend of any other suggestions?
  }

}