# NFT-Lending
NFT Lending Protocol with Backend Service

# Smart Contract
Smart Contract is located in the contracts folder and is written in Solidity. It is compiled using Remix IDE and deploy to the Sepolia Testnet.

Lending Protocol Contract: https://sepolia.etherscan.io/address/0x45765f1ca42ca73865248865f4cb0d2645cebc5f

FakeUSDT Contract: https://sepolia.etherscan.io/address/0x45942dd3a289bf7c088b8ebe2c61465437616cad

# Backend Service
Backend Service is written in Node.js. It is used to track the NFTs, transactions and NFT Transfers.

## How to run
1. Install dependencies
```
npm install moralis express @moralisweb3/common-evm-utils
npm install dotenv
npm install ejs
```
2. Enter Api Key in config/.env

3. Run the server
```
npm run server
```
4. Open server in browser at
```
http://localhost:3000
```

## API
1. <a href="https://moralis.io/" target="_blank">moralis.io</a> - a scalable Web3 backend provider that solves all the problems associated with appearing in Web3.

## Smart Contract Functions
### NFTLending
<p/> setFee - a function for setting the fee for using NFTs.
<p/> getNFTs - a function that returns a list of registered NFTs.
<p/> registerNFT - a private function for adding a new NFT to the list of registered ones.
<p/> purposeNFT/purposeNFTWithUSDT - a function for offering an NFT for rent to another user at a specified price and for a certain period of time.
<p/> purchaseNFT/purchaseNFTWithUSDT - a function for sending an NFT to a user after they have paid the rental fee.
<p/> cancelPurposeNFT - a function for cancelling an NFT rental offer and returning it to the owner.
<p/> returnNFT - function for returning the NFT to the owner and sending funds to the temporary owner.
<p/> withdrawAll - a function for withdrawing funds from the NFT to the owner.

### FakeUSDT
<p/> transfer - a function for transferring funds from one user to another.
<p/> balanceOf - a function for checking the balance of a user.
<p/> approve - a function for approving the transfer of funds from one user to another.
<p/> transferFrom - a function for transferring funds from one user to another after approval.
<p/> allowance - a function for checking the amount of funds approved for transfer.
