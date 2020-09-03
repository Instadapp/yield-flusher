// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface IndexInterface {
  function master() external view returns (address);
}

contract Registry {

  event LogAddChief(address indexed chief);
  event LogRemoveChief(address indexed chief);
  event LogAddSigner(address indexed signer);
  event LogRemoveSigner(address indexed signer);
  event LogConnectorEnable(address indexed connector);
  event LogConnectorDisable(address indexed connector);

  mapping(address => bool) public connectors;
  mapping (address => bool) public chief;
  mapping (address => bool) public signer;

  IndexInterface public instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

  modifier isMaster() {
    require(msg.sender == instaIndex.master(), "not-master");
    _;
  }

  modifier isController() {
    require(chief[msg.sender] || msg.sender == instaIndex.master(), "not-chief");
    _;
  }

  function enableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(!chief[_chief], "chief-already-enabled");
    chief[_chief] = true;
    emit LogAddChief(_chief);
  }

  function disableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(chief[_chief], "chief-already-disabled");
    delete chief[_chief];
    emit LogRemoveChief(_chief);
  }

  function enableConnector(address _connector) external isController {
    require(!connectors[_connector], "already-enabled");
    require(_connector != address(0), "invalid-connector");
    connectors[_connector] = true;
    emit LogConnectorEnable(_connector);
  }

  function disableConnector(address _connector) external isController {
    require(connectors[_connector], "already-disabled");
    delete connectors[_connector];
    emit LogConnectorDisable(_connector);
  }

  function enableSigner(address _signer) external isController {
    require(_signer != address(0), "address-not-valid");
    require(!signer[_signer], "signer-already-enabled");
    signer[_signer] = true;
    emit LogAddSigner(_signer);
  }

  function disableSigner(address _signer) external isController {
    require(_signer != address(0), "address-not-valid");
    require(signer[_signer], "signer-already-disabled");
    delete signer[_signer];
    emit LogRemoveSigner(_signer);
  }

  function isConnector(address[] calldata _connectors) external view returns (bool isOk) {
    isOk = true;
    for (uint i = 0; i < _connectors.length; i++) {
      if (!connectors[_connectors[i]]) {
        isOk = false;
        break;
      }
    }
  }

}