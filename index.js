require('dotenv').config({ path: 'config/.env' })

const Moralis = require("moralis").default;
const express = require("express");
const { EvmChain } = require("@moralisweb3/common-evm-utils");

const API_KEY = process.env.API_KEY;
const address = "0xA3DE3a58680606EDcba006a3b32a2a6448076aE2"

const abi = require("./abi.json");
const chain = EvmChain.SEPOLIA;
const app = express();

app.use(express.static(__dirname + '/public'));
app.set('view engine', 'ejs');

Moralis.start({
    apiKey: API_KEY,
});

// getAllNFTs() - Get all NFTs owned by the user
async function getAllNFTs() {
    const functionName = "getNFTs";
    const response = await Moralis.EvmApi.utils.runContractFunction({
      address,
      functionName,
      abi,
      chain,
    });

    const nfts = response.toJSON().map(([addr, tokenId, contractAddr, value, available]) => ({ addr, tokenId, contractAddr, value, available }));

    return nfts;
}

// getNFTsByCollection() - Get all NFTs owned by the user, grouped by collection
async function getNFTsByCollection() {
    let nfts = await getAllNFTs();
    if (!nfts || nfts.length === 0) {
        console.log("No NFTs found");
        return [];
    }

    const availableNFTs = nfts.filter(nft => nft.available);

    const nftPromises = availableNFTs.map(async nft => {
        const response = await Moralis.EvmApi.nft.getNFTMetadata({
            "chain": chain,
            "address": nft.contractAddr,
            "tokenId": nft.tokenId,
            "mediaItems": true
        });

        response.jsonResponse.available = nft.available;
        response.jsonResponse.value = nft.value;
        return response;
    });

    const nftsByCollection = await Promise.all(nftPromises);
    return nftsByCollection;
}

// getTransactions() - Get all transactions from address
async function getTransactions() {
    const response = await Moralis.EvmApi.transaction.getWalletTransactions({
        address,
        chain,
    });

    return response.toJSON().result;
}

// getNFTTransfers() - Get all NFT transfers from address
async function getNFTTransfers() {
    const response = await Moralis.EvmApi.nft.getWalletNFTTransfers({
        "chain": chain,
        "format": "decimal",
        "direction": "both", 
        "address": address,
      });

      return response.toJSON().result;
}

// handleRoute() - Handle route requests and render view with data
async function handleRoute(req, res, getData, viewName) {
    try {
        const data = await getData();
        res.render(viewName, { data });
    } catch(err) {
        console.error(err);
        res.status(500).send('Internal Server Error');
    }
}

// startService() - Start the service on port 3000
const startService = async () => {
    const port = 3000;
    app.listen(port, () => {
        console.log(`Service listening on port ${port}`);
    });
};

startService();


// Routes for the service - /nfts, /transactions, /nft-transfers
app.get('/nfts', async (req, res) => {
    await handleRoute(req, res, getNFTsByCollection, 'nfts')
});

app.get("/transactions", async (req, res) => {
    await handleRoute(req, res, getTransactions, 'transactions');
});

app.get("/nft-transfers", async(req, res) => {
    await handleRoute(req, res, getNFTTransfers, 'nft-transfers');
});

app.get("/", async (req, res) => {
    res.redirect('/nfts');
});
