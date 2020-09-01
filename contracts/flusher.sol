// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface RegistryInterface {
  function signer(address) external view returns (bool);
  function isConnector(address[] calldata) external view returns (bool);
}

contract Flusher {
  event LogCast(address indexed sender, uint value);

  RegistryInterface public constant registry = RegistryInterface(address(0)); // TODO - Change while deploying.

  modifier isSigner {
    require(registry.signer(msg.sender), "not-signer");
    _;
  }

  /**
    * @dev Delegate the calls to Connector And this function is ran by cast().
    * @param _target Target to of Connector.
    * @param _data CallData of function in Connector.
  */
  function spell(address _target, bytes memory _data) internal {
    require(_target != address(0), "target-invalid");
    assembly {
      let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

      switch iszero(succeeded)
        case 1 {
            // throw if delegatecall failed
            let size := returndatasize()
            returndatacopy(0x00, 0x00, size)
            revert(0x00, size)
        }
    }
  }

  /**
    * @dev Array of spell()
    * @param _targets Array of Target(s) to of Connector.
    * @param _datas Array of Calldata(s) of function.
  */
  function cast(address[] calldata _targets, bytes[] calldata _datas) external payable isSigner {
    require(_targets.length == _datas.length , "array-length-invalid");
    require(registry.isConnector(_targets), "not-connector");
    for (uint i = 0; i < _targets.length; i++) {
        spell(_targets[i], _datas[i]);
    }
    emit LogCast(msg.sender, msg.value);
  }

  receive() external payable {}
}