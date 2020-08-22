pragma solidity ^0.6.8;

interface IFlusher {
  function init(address, address) external;
}

contract Deployer {

  /**
    * @dev deploy create2 + minimal proxy
    * @param _owner owner address.
    * @param _target flusher contract address.
    * @param _token token address.
  */
  function deployFlusher(address _owner, address _target, address _token) public returns (address proxy) {
    bytes32 salt = keccak256(abi.encodePacked(_owner));
    bytes20 targetBytes = bytes20(_target);
    // solium-disable-next-line security/no-inline-assembly
    assembly {
        let clone := mload(0x40)
        mstore(
            clone,
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
        )
        mstore(add(clone, 0x14), targetBytes)
        mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
        )
        proxy := create2(0, clone, 0x37, salt)
    }
    IFlusher(proxy).init(_owner, _token);
  }

  /**
    * @dev Compute Create2 + Minimal Proxy address
    * @param _owner owner address.
    * @param _target flusher contract address.
  */
  function getDeploymentAddress(address _owner, address _target) public view returns (address) {
    bytes32 codeHash = keccak256(getMinimalProxyCreationCode(_target));
    bytes32 salt = keccak256(abi.encodePacked(_owner));
    bytes32 rawAddress = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        codeHash
      ));
      return address(bytes20(rawAddress << 96));
  }
  
  function getMinimalProxyCreationCode(address _target) public pure returns (bytes memory) {
    bytes20 a = bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73);
    bytes20 b = bytes20(_target);
    bytes15 c = bytes15(0x5af43d82803e903d91602b57fd5bf3);
    return abi.encodePacked(a, b, c);
  }
}