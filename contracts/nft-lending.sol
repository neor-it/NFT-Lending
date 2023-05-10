// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Імпортуємо інтерфейс ERC721

// Оголошення структури для зберігання інформації про NFT
struct Nft {
    address owner;
    address newOwner;
    uint256 tokenId;
    address nftContract;
    uint256 nftValue;
    uint256 useTime;
    uint256 timestamp;
    bool isAvailable;
}

contract NFTLending {
    Nft[] nfts; // Список зареєстрованих NFT
    event NFTReceived(address from, uint256 tokenId); // Подія, яка викликається при отриманні NFT
    address public owner = msg.sender; // Адреса власника контракту
    uint256 public fee = 1; // 1 wei

    // Функція для встановлення комісії за використання NFT
    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee");
        fee = _fee;
    }

    // Функція для отримання списку зареєстрованих NFT
    function getNFTs() public view returns (Nft[] memory) {
        return nfts;
    }

    // Функція додавання нового NFT до списку зареєстрованих
    function registerNFT(address _owner, address _newOwner, uint256 _tokenId, address _nftContract, uint256 _nftValue, uint256 useTime, uint256 _timestamp, bool _isAvaliable) private {
        nfts.push(Nft({
            owner: _owner,
            newOwner: _newOwner,
            tokenId: _tokenId,
            nftContract: _nftContract,
            nftValue: _nftValue + fee,
            useTime: useTime,
            timestamp: _timestamp,
            isAvailable: _isAvaliable
        }));
    }

    // Функція для пропонування NFT в оренду іншому користувачу під вказану ціну
    function purposeNFT(address _nftContract, uint256 _tokenId, uint256 _value, uint256 _useTime) public {
        // Перевіряємо чи відправник володіє NFT
        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        bool alreadyExists = false;
        uint256 nftIndex = 0;

        // Перевірка, чи є вже таке NFT у базі
        for (uint256 i = 0; i < nfts.length; i++) {
                
            if (nfts[i].tokenId == _tokenId && nfts[i].nftContract == _nftContract) {
                if (nfts[i].isAvailable) {
                    revert("NFT already registered and available for purchase!");
                }
                alreadyExists = true;
                nftIndex = i;
                break;
            }
        }

        if (alreadyExists){
            nfts[nftIndex].owner = msg.sender;
            nfts[nftIndex].newOwner = address(0);
            nfts[nftIndex].nftValue = _value + fee;
            nfts[nftIndex].useTime = _useTime;
            nfts[nftIndex].isAvailable = true;
        } else {
            registerNFT(msg.sender, address(0), _tokenId, _nftContract, _value, _useTime, 0, true);
        }

        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        emit NFTReceived(msg.sender, _tokenId); // Викликаємо подію NFTReceived
    }

    // Функція для відправки NFT збереженого на цьому контракті користувачу
    function purchaseNFT(address _nftContract, uint256 _tokenId) external payable {
        IERC721 nftContract = IERC721(_nftContract);

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
        require(msg.value >= nfts[nftIndex].nftValue, "Incorrect NFT value");

        // Викликаємо transferFrom на NFT-контракті, щоб відправити NFT
        nftContract.transferFrom(address(this), msg.sender, _tokenId);

        // Змінюємо статус NFT
        nfts[nftIndex].isAvailable = false;
        nfts[nftIndex].newOwner = msg.sender;
        nfts[nftIndex].timestamp = block.timestamp;
    }

    // Функція для відміни пропозиції оренди NFT і повернення його власнику
    function cancelPurposeNFT(address _nftContract, uint256 _tokenId) public {
        IERC721 nftContract = IERC721(_nftContract);

        bool found = false;
        uint256 nftIndex = 0;
        
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].tokenId == _tokenId && nfts[i].nftContract == _nftContract) {
                found = true;
                nftIndex = i;
                break;
            }
        }

        require(found, "NFT not found");

        nftContract.transferFrom(address(this), nfts[nftIndex].owner, _tokenId);

        nfts[nftIndex].isAvailable = false;
        nfts[nftIndex].newOwner = address(0);
    }

    // Функція для повернення NFT власнику
    function returnNFT(address _nftContract, uint256 _tokenId) external {
        IERC721 nftContract = IERC721(_nftContract);

        // Знаходимо NFT в колекції
        bool found = false;
        uint256 nftIndex = 0;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].newOwner == msg.sender && nfts[i].tokenId == _tokenId && nfts[i].nftContract == _nftContract && !nfts[i].isAvailable) {
                found = true;
                nftIndex = i;
                break;
            }
        }
        require(found, "NFT not found or not available");

        // Перевіряємо, що власник NFT викликає цю функцію
        require(nfts[nftIndex].newOwner == msg.sender, "Only temp-owner can return NFT");

        // Викликаємо transferFrom на NFT-контракті, щоб відправити NFT

        if (block.timestamp > nfts[nftIndex].timestamp + nfts[nftIndex].useTime) {
            // Якщо час використання вичерпано, то тимчасовий власник стає власником NFT і втрачає кошти
            revert("You cannot return NFT after use time");
        }
        
        nftContract.transferFrom(msg.sender, nfts[nftIndex].owner, _tokenId);

        address payable _newOwner = payable(nfts[nftIndex].newOwner);
        address payable _owner = payable(nfts[nftIndex].owner);

        _newOwner.transfer(nfts[nftIndex].nftValue - fee);
        _owner.transfer(fee);

        // Змінюємо статус NFT
        nfts[nftIndex].owner = nfts[nftIndex].newOwner;
        nfts[nftIndex].newOwner = address(0);
    }

    // Функція для зняття коштів за NFT власнику
    function withdrawAll() external {
        uint256 totalValue = 0;
        bool found = false;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].owner == msg.sender && nfts[i].isAvailable == false) {
                if (block.timestamp > nfts[i].timestamp + nfts[i].useTime) {
                    totalValue += nfts[i].nftValue;

                    nfts[i].owner = nfts[i].newOwner;
                    nfts[i].newOwner = address(0);
                    found = true;
                }
            }
        }

        if (!found) {
            revert("You cannot withdraw funds!");
        }

        if (totalValue == 0) {
            revert("You don't have funds to withdraw on this contract!");
        }

        payable(msg.sender).transfer(totalValue);
    }


    // Функція для отримання балансу контракту
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
