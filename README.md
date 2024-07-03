# EsimBlockchain

## Introduction

Some months ago I learned about the existence of Esims. They do not need a special SIM card to work but they give data plans abroad. I thought this could be a good idea to be implemented in Blockchain,
because it allows for fast decentralized transactions that allows user to very easily and only giving your phone number as info, obtain the service of this esims. Also,some phone companies usually tend to be
pretty annoying regarding the cancel of their data plans.


## Idea

Develop some Smart Contracts that manage the information:

## CountryInfoFactory.sol
Manages the user information and registry and creates contract for every country that the business gives services

## CountryInfo.sol
One contract per country. Stores the phone numbers that have plans and the plans attached to them. You can buy, Upgrade, cancel plans...

### Advantages

- Security: Blockchain's decentralized nature ensures that you are paying what you are buying. No small letter or scamming.
- Immutable Records: Once a transaction is recorded on the blockchain, it cannot be altered, ensuring the integrity of the purchases of data Plans and preventing disputes.
- Elimination of Intermediaries: By using blockchain, the user can directly cancel the plan without having workers of the company trying to get you back with calls and SMS.


### Disadvantages
- Depending on the chain deployed, might be very costly to update the contract
- Elderly people might get confused even if there´s only 1 simple step to create the address and buy a plan.
- Maybe difficult in some countries to declare the benefits to their tax office and give service to users, so it depends on the view of the country about data plans.
  
## RoadMap
- Testing both contracts
- Developing a simple App connected to metamask
- End!!!!!!
