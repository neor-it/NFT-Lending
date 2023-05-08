// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Імпортуємо інтерфейс ERC721

// Оголошення структури для зберігання інформації про NFT
struct Nft {
    address owner;
    uint256 tokenId;
    address nftContract;
    uint256 nftValue;
    bool isAvailable;
}

contract NFTLending {
    Nft[] nfts; // Список зареєстрованих NFT
    event NFTReceived(address from, uint256 tokenId); // Подія, яка викликається при отриманні NFT
    address public owner = msg.sender;

    function getNFTs() public view returns (Nft[] memory) {
        return nfts;
    }

    // Функція додавання нового NFT до списку зареєстрованих
    function registerNFT(address _owner, uint256 _tokenId, address _nftContract, uint256 _nftValue, bool _isAvaliable) private {
        nfts.push(Nft({
            owner: _owner,
            tokenId: _tokenId,
            nftContract: _nftContract,
            nftValue: _nftValue,
            isAvailable: _isAvaliable
        }));
    }

    function getNFTValue() private pure returns (uint8) {
        return 5; // 5 wei
    }

    function sendWei(address payable _recipient, uint256 _amount) private {
        require(address(this).balance >= _amount, "Insufficient balance"); // перевіряємо баланс контракту
        _recipient.transfer(_amount); // відправляємо wei користувачу
    }

    // Функція для отримання NFT від користувача на NFT-контракті (зберігає NFT на цьому контракті)
    function bailNFT(address _nftContract, uint256 _tokenId) external {
        // Викликаємо transferFrom на NFT-контракті, щоб отримати NFT
        IERC721 nftContract = IERC721(_nftContract);
        
        uint256 nftValue = getNFTValue();
        registerNFT(msg.sender, _tokenId, _nftContract, nftValue, true);
        sendWei(payable(msg.sender), nftValue);

        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        emit NFTReceived(msg.sender, _tokenId); // Викликаємо подію NFTReceived
    }

    // Функція для відправки NFT збереженого на цьому контракті користувачу
    function purchaseNFT(address _to, address _nftContract, uint256 _tokenId) external payable {
        // Знаходимо NFT в колекції
        bool found = false;
        uint256 nftIndex = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].tokenId == _tokenId && nfts[i].nftContract == _nftContract && nfts[i].isAvailable) {
                found = true;
                nftIndex = i;
                break;
            }
        }
        require(found, "NFT not found or not available");

        // Перевіряємо, що сума співпадає з вартістю NFT
        require(nfts[nftIndex].nftValue == msg.value, "Incorrect NFT value");

        // Викликаємо transferFrom на NFT-контракті, щоб відправити NFT
        IERC721 nftContract = IERC721(_nftContract);
        nftContract.transferFrom(address(this), _to, _tokenId);

        // Змінюємо статус NFT
        nfts[nftIndex].owner = _to;
        nfts[nftIndex].isAvailable = false;
    }

    function purchaseNFTByOwner(address _to, address _nftContract, uint256 _tokenId) external {
        require(msg.sender == owner, "This function can call only owner");
        IERC721 nftContract = IERC721(_nftContract);
        nftContract.transferFrom(address(this), _to, _tokenId);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() external payable {
        // Перевіряємо, що сума переведення не дорівнює 0
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }

    function withdrawAll(address payable _to) external {
        require(msg.sender == owner, "This function can call only owner");   
        require(address(this).balance > 0, "The balance for withdrawal must be greater than 0");
        _to.transfer(address(this).balance);
    }
}
