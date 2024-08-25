import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import ABI from "./abis/TokenMaster.json";

function App() {
  const [state, setState] = useState({
    provider: null,
    signer: null,
    contract: null,
  });
  const [account, setAccount] = useState('Not connected');
  const [networkName, setNetworkName] = useState("Unknown Network");
  const [rpcUrl, setRpcUrl] = useState("");
  const [totalOccasions, setTotalOccasions] = useState(0); // State to store the total occasions
  const [occasions, setOccasions] = useState([]); // State to store the occasion details

  useEffect(() => {
    const loadBlockchainData = async () => {
      try {
        if (window.ethereum) {
          const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
          setAccount(accounts[0]);

          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const signer = provider.getSigner();

          const network = await provider.getNetwork();
          console.log(network);

          let rpcUrl = '';
          if (network.chainId === 1) {
            rpcUrl = 'https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID';
          } else if (network.chainId === 4) {
            rpcUrl = 'https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID';
          } else if (network.chainId === 31337) {
            rpcUrl = 'http://localhost:8545';
          } else {
            rpcUrl = `Custom RPC URL for Chain ID: ${network.chainId}`;
          }
          setRpcUrl(rpcUrl);

          let networkName = network.name;
          if (network.chainId === 31337) {
            networkName = "Hardhat";
          } else if (networkName === "unknown") {
            networkName = `Unknown (Chain ID: ${network.chainId})`;
          }
          setNetworkName(networkName);

          // Create contract instance
          const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
          const contract = new ethers.Contract(contractAddress, ABI.abi, signer);
          console.log(contract);

          // Set the state with provider, signer, and contract
          setState({ provider, signer, contract });

          // Call totalOccasions function and update the state
          const total = await contract.totalOccasions();
          setTotalOccasions(total.toString()); // Convert to string and set state

          const occasionsData = [];
          for (let i = 1; i <= total; i++) {
            const occasion = await contract.getOccasion(i);
            occasionsData.push(occasion);
          }
          setOccasions(occasionsData); // Store all occasions in state

        } else {
          alert("MetaMask is not installed. Please install it to interact with this dApp.");
        }
      } catch (error) {
        console.error("An error occurred:", error);
      }
    };

    loadBlockchainData();
  }, []);

  return (
    <div>
      <img src="path-to-your-image" className="img-fluid" alt="TokenMaster" width="100%" />
      <p style={{ marginTop: "10px", marginLeft: "5px" }}>
        <small>Connected Account - {account}</small>
      </p>
      <div>
        <h2>Connected to Network: {networkName}</h2>
        <h2>RPC URL: {rpcUrl}</h2>
      </div>

      <div>
        <h2>Total Occasions: {totalOccasions}</h2> {/* Display the total occasions */}
      </div>

      <div>
        <h2>Occasion Details:</h2>
        {occasions.length > 0 ? (
          occasions.map((occasion, index) => (
            <div key={index}>
              <h3>Occasion {occasion.id}</h3>
              <p>Name: {occasion.name}</p>
              <p>Cost: {ethers.utils.formatEther(occasion.cost)} ETH</p>
              <p>Tickets Available: {occasion.tickets}</p>
              <p>Date: {occasion.date}</p>
              <p>Time: {occasion.time}</p>
              <p>Location: {occasion.location}</p>
            </div>
          ))
        ) : (
          <p>No occasions available.</p>
        )}
      </div>

      {/* Placeholder for your Buy and Memos components */}
      {/* <Buy state={state} /> */}
      {/* <Memos state={state} /> */}
    </div>
  );
}

export default App;
