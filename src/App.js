import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import TokenMaster from './abis/TokenMaster.json';

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [networkName, setNetworkName] = useState("Unknown Network");
  const [tokenMaster, setTokenMaster] = useState(null);
  const [occasions, setOccasions] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadBlockchainData = async () => {
    try {
      // Check if MetaMask is installed
      if (window.ethereum) {
        // Request account access from MetaMask
        await window.ethereum.request({ method: 'eth_requestAccounts' });

        // Connect to the local Hardhat network using MetaMask
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        setProvider(provider);

        const signer = provider.getSigner();
        setSigner(signer);

        const account = await signer.getAddress();
        setAccount(account);

        const network = await provider.getNetwork();
        
        // Ensure user is connected to Hardhat local network
        if (network.chainId !== 31337) {
          alert("Please connect MetaMask to the Hardhat local network.");
          return;
        }

        // Manually map network name if it's not recognized
        let networkName = network.name;
        if (network.chainId === 31337) { // Hardhat's default chain ID
          networkName = "Hardhat";
        } else if (networkName === "unknown") {
          networkName = `Unknown (Chain ID: ${network.chainId})`;
        }
        setNetworkName(networkName);

        // Connect to the contract
        const tokenMaster = new ethers.Contract(
          "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707", // Replace with your contract address
          TokenMaster.abi,
          signer // Use the signer here
        );
        setTokenMaster(tokenMaster);

        // Fetch total occasions
        const totalOccasions = await tokenMaster.totalOccasions();
        const occasions = [];

        for (let i = 1; i <= totalOccasions; i++) {
          const occasion = await tokenMaster.getOccasion(i);
          occasions.push(occasion);
        }

        setOccasions(occasions);
        setLoading(false);

      } else {
        alert("MetaMask is not installed. Please install it to interact with this dApp.");
      }

    } catch (error) {
      console.error("An error occurred:", error);
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBlockchainData();
  }, []);

  const handlePurchase = async (occasionId, amount) => {
    try {
      const tx = await tokenMaster.purchaseTicket(occasionId, { value: ethers.utils.parseEther(amount) });
      await tx.wait();
      alert("Ticket purchased successfully!");
    } catch (error) {
      console.error("Purchase failed:", error);
    }
  };

  return (
    <div>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div>
          <h2>Connected to Network: {networkName}</h2>
          <h2>Connected Account: {account}</h2>
          {occasions.length === 0 ? (
            <h2>No Occasions</h2>
          ) : (
            <div>
              <h2>Total Occasions: {occasions.length}</h2>
              <ul>
                {occasions.map((occasion, index) => (
                  <li key={index}>
                    <h3>{occasion.name}</h3>
                    <p>Date: {occasion.date}</p>
                    <p>Time: {occasion.time}</p>
                    <p>Location: {occasion.location}</p>
                    <p>Cost: {ethers.utils.formatEther(occasion.cost)} ETH</p>
                    <p>Tickets Available: {occasion.tickets}</p>
                    <button onClick={() => handlePurchase(index + 1, "0.1")}>
                      Purchase Ticket
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default App;
