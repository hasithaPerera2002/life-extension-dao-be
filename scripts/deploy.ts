import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const AddressManager = await ethers.getContractFactory("AddressManager");
  const addressManager = await AddressManager.deploy();
  await addressManager.waitForDeployment();
  const addressManagerAddr = await addressManager.getAddress();
  console.log("AddressManager deployed to:", addressManagerAddr);

  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(addressManagerAddr);
  await governance.waitForDeployment();
  const governanceAddr = await governance.getAddress();
  console.log("Governance deployed to:", governanceAddr);

  const Members = await ethers.getContractFactory("Members");
  const members = await Members.deploy(addressManagerAddr, deployer.address);
  await members.waitForDeployment();
  const membersAddr = await members.getAddress();
  console.log("Members deployed to:", membersAddr);

  const Payouts = await ethers.getContractFactory("Payouts");
  const payouts = await Payouts.deploy(addressManagerAddr, deployer.address);
  await payouts.waitForDeployment();
  const payoutsAddr = await payouts.getAddress();
  console.log("Payouts deployed to:", payoutsAddr);

  const Proposal = await ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy(addressManagerAddr);
  await proposal.waitForDeployment();
  const proposalAddr = await proposal.getAddress();
  console.log("Proposal deployed to:", proposalAddr);

  await addressManager.setContracts(governanceAddr, membersAddr, proposalAddr, payoutsAddr);
  console.log("AddressManager.setContracts() called");

  await members.bootstrapGovernance(governanceAddr, proposalAddr, payoutsAddr);
  console.log("Governance contract refs set (via Members.bootstrapGovernance)");

  await members.setGovernanceContract(governanceAddr);
  await members.setProposalContract(proposalAddr);
  await members.setPayoutsContract(payoutsAddr);
  console.log("Members contract refs set");

  await payouts.setGovernanceContract(governanceAddr);
  await payouts.setMemberContract(membersAddr);
  await payouts.setProposalContract(proposalAddr);
  console.log("Payouts contract refs set");

  await proposal.setGovernanceContract(governanceAddr);
  await proposal.setMemberContract(membersAddr);
  console.log("Proposal contract refs set");

  console.log("\nDeployment complete. Addresses:");
  console.log({ addressManager: addressManagerAddr, governance: governanceAddr, members: membersAddr, payouts: payoutsAddr, proposal: proposalAddr });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
