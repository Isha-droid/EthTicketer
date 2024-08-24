import { useEffect, useState } from 'react';
import Web3 from 'web3';
import TokenMaster from './abis/TokenMaster.json';

function App() {
  const [totalOccasions, setTotalOccasions] = useState(null);
  const [occasions, setOccasions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [account, setAccount] = useState(null);
  const [web3, setWeb3] = useState(null);

  useEffect(() => {
    const initWeb3 = async () => {
      let web3Instance;
      if (window.ethereum) {
        try {
          // Initialize Web3 with MetaMask provider
          web3Instance = new Web3(window.ethereum);
          await window.ethereum.request({ method: 'eth_requestAccounts' });
        } catch (error) {
          console.error("MetaMask error:", error);
          // Fall back to local provider if MetaMask is not working
          web3Instance = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
        }
      } else {
        // MetaMask not detected, use local provider
        web3Instance = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
      }

      setWeb3(web3Instance);
      
      try {
        // Get accounts
        const accounts = await web3Instance.eth.getAccounts();
        setAccount(accounts[0]);

        // Load blockchain data
        loadBlockchainData(web3Instance);
      } catch (error) {
        console.error("Error retrieving accounts:", error);
      }
    };

    initWeb3();
  }, []);

  const loadBlockchainData = async (web3Instance) => {
    try {
      const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
      const tokenMaster = new web3Instance.eth.Contract(TokenMaster.abi, contractAddress);

      // Get total occasions
      const totalOccasions = await tokenMaster.methods.totalOccasions().call();
      setTotalOccasions(totalOccasions);

      // Fetch each occasion's details
      const occasions = [];
      for (let i = 1; i <= totalOccasions; i++) {
        const occasion = await tokenMaster.methods.getOccasion(i).call();
        occasions.push(occasion);
      }

      setOccasions(occasions);
      setLoading(false);
    } catch (error) {
      console.error("Error loading blockchain data:", error);
      setLoading(false);
    }
  };

  return (
    <div>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div>
          <h2>Connected Account: {account}</h2>
          {totalOccasions === '0' ? (
            <h2>No Occasions</h2>
          ) : (
            <div>
              <h2>Total Occasions: {totalOccasions}</h2>
              <ul>
                {occasions.map((occasion) => (
                  <li key={occasion.id}>
                    <h3>{occasion.name}</h3>
                    <p>Date: {occasion.date}</p>
                    <p>Time: {occasion.time}</p>
                    <p>Location: {occasion.location}</p>
                    <p>Cost: {web3.utils.fromWei(occasion.cost, 'ether')} ETH</p>
                    <p>Tickets Available: {occasion.tickets}</p>
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
