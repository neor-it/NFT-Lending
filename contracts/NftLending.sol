// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Import the ERC721 interface
import "./FakeUSDT.sol";

// Struct for storing NFT data
struct Nft {
    address owner;
    address newOwner;
    uint256 tokenId;
    address nftContract;
    uint256 nftValue;
    uint256 usdtValue;
    uint256 useTime;
    uint256 timestamp;
    bool isAvailable;
}

// Struct for storing key data
struct KeyData {
    address[] contractAddresses;
    uint256[] tokenIds;
}

contract NFTLending {
    mapping(address => mapping(uint256 => Nft)) public nfts; // Mapping for storing NFT data
    mapping(address => KeyData) private nftKeys; // Mapping for storing key data
    address []ownerAddresses; // Array for storing owner addresses
    uint nftCount; // Count of registered NFTs on the contract
    FakeUSDT public fakeUSDT;

    event NFTReceived(address from, uint256 tokenId); // Event for receiving NFT
    address public owner = msg.sender; // Address of the contract owner
    uint256 public fee = 1; // 1 wei

    function setFakeUSDTContract(address _fakeUSDTAddress) public {
        require(msg.sender == owner, "Only owner can set FakeUSDT contract");
        fakeUSDT = FakeUSDT(_fakeUSDTAddress);
    }

    // Function for setting fee
    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee");
        fee = _fee;
    }

    // Function for getting NFT list
    function getAllNFTs() public view returns (Nft[] memory) {
        Nft[] memory nftList = new Nft[](nftCount);
        uint index = 0;
        
        for (uint i = 0; i < ownerAddresses.length; i++) {
            address _owner = ownerAddresses[i];
            KeyData storage keyData = nftKeys[_owner];
            address[] storage contractAddresses = keyData.contractAddresses;
            uint256[] storage tokenIds = keyData.tokenIds;
            
            for (uint j = 0; j < contractAddresses.length; j++) {
                address nftContract = contractAddresses[j];
                uint256 tokenId = tokenIds[j];
                Nft storage nft = nfts[nftContract][tokenId];
                nftList[index] = nft;
                index++;
            }
        }

        return nftList;
    }

    // Function for registering NFT
    function registerNFT(address _owner, address _newOwner, address _nftContract, uint256 _tokenId, uint256 _nftValue, uint256 _usdtValue, uint256 _useTime, uint256 _timestamp, bool _isAvailable) private {
        uint256 funds = 0;

        // Check if _nftValue > 0 set fee
        if (_nftValue > 0) {
            funds = _nftValue + fee;
        }

        nfts[_nftContract][_tokenId] = Nft({
            owner: _owner,
            newOwner: _newOwner,
            tokenId: _tokenId,
            nftContract: _nftContract,
            nftValue: funds,
            usdtValue: _usdtValue,
            useTime: _useTime,
            timestamp: _timestamp,
            isAvailable: _isAvailable
        });

        nftKeys[_owner].contractAddresses.push(_nftContract);
        nftKeys[_owner].tokenIds.push(_tokenId);
        ownerAddresses.push(_owner);
        nftCount++;
    }

    // Function for deleting NFT    
    function deleteNFT(address _owner, address _nftContract, uint256 _tokenId) private {
        delete nfts[_nftContract][_tokenId];

        KeyData storage keyData = nftKeys[_owner];
        address[] storage contractAddresses = keyData.contractAddresses;
        uint256[] storage tokenIds = keyData.tokenIds;

        for (uint i = 0; i < contractAddresses.length; i++) {
            if (contractAddresses[i] == _nftContract && tokenIds[i] == _tokenId) {
                contractAddresses[i] = contractAddresses[contractAddresses.length - 1];
                delete contractAddresses[contractAddresses.length - 1];
                contractAddresses.pop();

                tokenIds[i] = tokenIds[tokenIds.length - 1];
                delete tokenIds[tokenIds.length - 1];
                tokenIds.pop();

                break;
            }
        }

        for (uint i = 0; i < ownerAddresses.length; i++) {
            if (ownerAddresses[i] == _owner) {
                ownerAddresses[i] = ownerAddresses[ownerAddresses.length - 1];
                delete ownerAddresses[ownerAddresses.length - 1];
                ownerAddresses.pop();

                break;
            }
        }

        nftCount--;
    }

    // Function for purpose NFT
    function purposeNFT(address _nftContract, uint256 _tokenId, uint256 _value, uint256 _useTime) public {
        // Check if sender have NFT
        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        
        // Check if NFT is not registered
        Nft storage nftData = nfts[_nftContract][_tokenId];
        require(!nftData.isAvailable, "NFT already registered");

        if (nftData.nftContract != address(0)) {
            require(block.timestamp > (nftData.timestamp + nftData.useTime), "NFT is not available");
            
            if (nftData.usdtValue > 0) {
                // Sending funds to NFT owner
                fakeUSDT.transfer(nftData.owner, nftData.usdtValue);
            } else {
                // Sending funds to NFT owner
                address payable _owner = payable(nftData.owner);
                _owner.transfer(nftData.nftValue);
            }

            // Deleting NFT from contract
            deleteNFT(nftData.owner, nftData.nftContract, nftData.tokenId);
        }

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        // Adding NFT to registered list
        registerNFT(msg.sender, address(0), _nftContract, _tokenId, _value, 0, _useTime, block.timestamp, true);

        emit NFTReceived(msg.sender, _tokenId);
    }

    function purposeNFTWithUSDT(address _nftContract, uint256 _tokenId, uint256 _value, uint256 _useTime) public {
        // Check if sender have NFT
        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        // Check if NFT is not registered
        Nft storage nftData = nfts[_nftContract][_tokenId];
        require(!nftData.isAvailable, "NFT already registered");

        if (nftData.nftContract != address(0)) {
            require(block.timestamp > (nftData.timestamp + nftData.useTime), "NFT is not available");
            
            // Проверить за что был продан NFT (USDT или ETH)
            if (nftData.usdtValue > 0) {
                // Sending funds to NFT owner
                fakeUSDT.transfer(nftData.owner, nftData.usdtValue);
            } else {
                // Sending funds to NFT owner
                address payable _owner = payable(nftData.owner);
                _owner.transfer(nftData.nftValue);
            }

            // Deleting NFT from contract
            deleteNFT(nftData.owner, nftData.nftContract, nftData.tokenId);
        }

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        // Adding NFT to registered list
        registerNFT(msg.sender, address(0), _nftContract, _tokenId, 0, _value, _useTime, block.timestamp, true);

        emit NFTReceived(msg.sender, _tokenId);
    }

    // Function for sending NFT from this contract to user
    function purchaseNFT(address _nftContract, uint256 _tokenId) external payable {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.isAvailable, "NFT not found or not available");

        // check if owner is not trying to buy his own NFT
        require(nftData.owner != msg.sender, "You can't buy your own NFT");

        // Check if value is equal to NFT value
        require(msg.value == nftData.nftValue, "Incorrect NFT value");
        
        IERC721 nftContract = IERC721(_nftContract);
        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(address(this), msg.sender, _tokenId);

        // Change NFT status to not available
        nftData.isAvailable = false;
        nftData.newOwner = msg.sender;
        nftData.timestamp = block.timestamp;
    }

    // Function for sending NFT from this contract to user with USDT
    function purchaseNFTWithUSDT(uint256 amount, address _nftContract, uint256 _tokenId) external {
        Nft storage nftData = nfts[_nftContract][_tokenId];
        
        require(nftData.isAvailable, "NFT not found or not available");

        // check if owner is not trying to buy his own NFT
        require(nftData.owner != msg.sender, "You can't buy your own NFT");

        // Check if user have enough USDT
        require(fakeUSDT.balanceOf(msg.sender) >= amount, "Not enough USDT");

        // Check if value is equal to NFT value
        require(amount == nftData.usdtValue, "Incorrect NFT value");

        // Check if this NFT was purchased with USDT
        require(nftData.usdtValue > 0, "This NFT wasn't purchased with USDT");

        IERC721 nftContract = IERC721(_nftContract);

        // Call transferFrom on the NFT contract to send NFT to this contract
        nftContract.transferFrom(address(this), msg.sender, _tokenId);

        // Change NFT status to not available
        nftData.isAvailable = false;
        nftData.newOwner = msg.sender;
        nftData.timestamp = block.timestamp;

        // Send USDT to Smart Contract
        fakeUSDT.transferFrom(msg.sender, address(this), amount);
    }

    // Function for canceling NFT purpose and returning it to owner
    function cancelPurposeNFT(address _nftContract, uint256 _tokenId) public {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.owner == msg.sender, "NFT not found");

        IERC721 nftContract = IERC721(_nftContract);

        nftContract.transferFrom(address(this), nftData.owner, _tokenId);

        deleteNFT(nftData.owner, _nftContract, _tokenId);
    }

    // Function for returning NFT to owner
    function returnNFT(address _nftContract, uint256 _tokenId) external {
        Nft storage nftData = nfts[_nftContract][_tokenId];

        require(nftData.newOwner == msg.sender, "Only temp-owner can return NFT");

        IERC721 nftContract = IERC721(_nftContract);

        require(block.timestamp < nftData.timestamp + nftData.useTime, "You cannot return NFT after use time");
        
        nftContract.transferFrom(msg.sender, nftData.owner, _tokenId);

        address payable _newOwner = payable(nftData.newOwner);
        address payable _owner = payable(nftData.owner);

        // Check if NFT was purchased with USDT or ETH and send funds to owner
        if (nftData.usdtValue > 0) {
            fakeUSDT.transfer(nftData.newOwner, nftData.usdtValue);
        } else {
            _newOwner.transfer(nftData.nftValue - fee);
            _owner.transfer(fee);
        }

        deleteNFT(nftData.owner, _nftContract, _tokenId);
    }

    // Function for withdraw funds for NFT owner
    function withdrawAll() external {
        uint256 ethAmount = 0;
        uint256 usdtAmount = 0;
        address payable _owner = payable(msg.sender);

        Nft[] memory nftList = getAllNFTs();

        for (uint256 i = 0; i < nftList.length; i++) {
            Nft storage nftData = nfts[nftList[i].nftContract][nftList[i].tokenId];

            if (nftData.owner == msg.sender && !nftData.isAvailable && block.timestamp >= (nftData.useTime + nftData.timestamp)) {
                usdtAmount += nftData.usdtValue;
                ethAmount += nftData.nftValue;

                deleteNFT(msg.sender, nftList[i].nftContract, nftList[i].tokenId);
            }
        }

        require(ethAmount > 0 || usdtAmount > 0, "You don't have funds to withdraw on this contract!");
        
        if (ethAmount > 0) {
            _owner.transfer(ethAmount);
        }

        if (usdtAmount > 0) {
            fakeUSDT.transfer(_owner, usdtAmount);
        }
    }
}
