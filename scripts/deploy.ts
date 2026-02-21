import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  let nextNonce = await deployer.getNonce("pending");
  const txOpts = () => ({ nonce: nextNonce++ });

  const AddressManager = await ethers.getContractFactory("AddressManager");
  const addressManager = await AddressManager.deploy(txOpts());
  await addressManager.waitForDeployment();
  const addressManagerAddr = await addressManager.getAddress();
  console.log("AddressManager deployed to:", addressManagerAddr);

  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(addressManagerAddr, txOpts());
  await governance.waitForDeployment();
  const governanceAddr = await governance.getAddress();
  console.log("Governance deployed to:", governanceAddr);

  const Members = await ethers.getContractFactory("Members");
  const members = await Members.deploy(
    addressManagerAddr,
    deployer.address,
    txOpts()
  );
  await members.waitForDeployment();
  const membersAddr = await members.getAddress();
  console.log("Members deployed to:", membersAddr);

  const Payouts = await ethers.getContractFactory("Payouts");
  const payouts = await Payouts.deploy(
    addressManagerAddr,
    deployer.address,
    txOpts()
  );
  await payouts.waitForDeployment();
  const payoutsAddr = await payouts.getAddress();
  console.log("Payouts deployed to:", payoutsAddr);

  const Proposal = await ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy(addressManagerAddr, txOpts());
  await proposal.waitForDeployment();
  const proposalAddr = await proposal.getAddress();
  console.log("Proposal deployed to:", proposalAddr);

  const setContractsTx = await addressManager.setContracts(
    governanceAddr,
    membersAddr,
    proposalAddr,
    payoutsAddr,
    txOpts()
  );
  await setContractsTx.wait();
  console.log("AddressManager.setContracts() called");

  const setGovMemberTx = await governance.setMemberContract(
    membersAddr,
    txOpts()
  );
  await setGovMemberTx.wait();
  const setGovProposalTx = await governance.setProposalContract(
    proposalAddr,
    txOpts()
  );
  await setGovProposalTx.wait();
  const setGovPayoutsTx = await governance.setPayoutsContract(
    payoutsAddr,
    txOpts()
  );
  await setGovPayoutsTx.wait();
  console.log("Governance contract refs set");

  const setMembersGovTx = await members.setGovernanceContract(
    governanceAddr,
    txOpts()
  );
  await setMembersGovTx.wait();
  const setMembersProposalTx = await members.setProposalContract(
    proposalAddr,
    txOpts()
  );
  await setMembersProposalTx.wait();
  const setMembersPayoutsTx = await members.setPayoutsContract(
    payoutsAddr,
    txOpts()
  );
  await setMembersPayoutsTx.wait();
  console.log("Members contract refs set");

  const setPayoutsGovTx = await payouts.setGovernanceContract(
    governanceAddr,
    txOpts()
  );
  await setPayoutsGovTx.wait();
  const setPayoutsMemberTx = await payouts.setMemberContract(
    membersAddr,
    txOpts()
  );
  await setPayoutsMemberTx.wait();
  const setPayoutsProposalTx = await payouts.setProposalContract(
    proposalAddr,
    txOpts()
  );
  await setPayoutsProposalTx.wait();
  console.log("Payouts contract refs set");

  const setProposalGovTx = await proposal.setGovernanceContract(
    governanceAddr,
    txOpts()
  );
  await setProposalGovTx.wait();
  const setProposalMemberTx = await proposal.setMemberContract(
    membersAddr,
    txOpts()
  );
  await setProposalMemberTx.wait();
  console.log("Proposal contract refs set");

  console.log("\nDeployment complete. Addresses:");
  console.log({ addressManager: addressManagerAddr, governance: governanceAddr, members: membersAddr, payouts: payoutsAddr, proposal: proposalAddr });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
