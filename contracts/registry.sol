// SPDX-License-Identifier: MIT

// QUES:
// could we just have switch<name> for instead of all the enable/disable functions? (like switchConnector)?

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface IndexInterface {
  function master() external view returns (address);
}

contract Registry {

  event LogAddChief(address indexed chief);
  event LogAddSigner(address indexed signer);
  event LogRemoveChief(address indexed chief);
  event LogRemoveSigner(address indexed signer);
  event LogConnectorEnable(address indexed connector);
  event LogConnectorDisable(address indexed connector);

  mapping(address => bool) public connectors;

  IndexInterface public instaIndex;

  mapping (address => bool) public chief;
  mapping (address => bool) public signer;

  modifier isMaster() {
    require(msg.sender == instaIndex.master(), "not-master");
    _;
  }

  modifier isController() {
    require(chief[msg.sender] || msg.sender == instaIndex.master(), "not-chief");
    _;
  }

  constructor(address _index) public {
    instaIndex = IndexInterface(_index);
  }

  /**
    * @dev Enable New Chief.
    * @param _chief Address of the new chief.
  */
  function enableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(!chief[_chief], "chief-already-enabled");
    chief[_chief] = true;
    emit LogAddChief(_chief);
  }

  /**
    * @dev Disable Chief.
    * @param _chief Address of the existing chief.
  */
  function disableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(chief[_chief], "chief-already-disabled");
    delete chief[_chief];
    emit LogRemoveChief(_chief);
  }

  /**
    * @dev Enable Connector.
    * @param _connector Connector Address.
  */
  function enableConnector(address _connector) external isController {
    require(!connectors[_connector], "already-enabled");
    require(_connector != address(0), "Not-valid-connector");
    connectors[_connector] = true;
    emit LogConnectorEnable(_connector);
  }
  /**
    * @dev Disable Connector.
    * @param _connector Connector Address.
  */
  function disableConnector(address _connector) external isController {
    require(connectors[_connector], "already-disabled");
    delete connectors[_connector];
    emit LogConnectorDisable(_connector);
  }

  /**
    * @dev Enable New Signer.
    * @param _signer Address of the new signer.
  */
  function enableSigner(address _signer) external isController {
    require(_signer != address(0), "address-not-valid");
    require(!signer[_signer], "signer-already-enabled");
    signer[_signer] = true;
    emit LogAddSigner(_signer);
  }

  /**
    * @dev Disable Signer.
    * @param _signer Address of the existing signer.
  */
  function disableSigner(address _signer) external isController {
    require(_signer != address(0), "address-not-valid");
    require(signer[_signer], "signer-already-disabled");
    delete signer[_signer];
    emit LogRemoveSigner(_signer);
  }

  /**
    * @dev Check if Connector addresses are enabled.
    * @param _connectors Array of Connector Addresses.
  */
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
