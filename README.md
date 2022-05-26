# Auto Dollar Cost Averaging

DCA - this is one of the simplest investment strategy in which an investor divides up the total amount to be invested across periodic purchases of a target asset in an effort to reduce the impact of volatility on the overall purchase. The term was coined by Benjamin Graham.

Developed app helps to automate this strategy. User has to deploy contracts on any EVM chain supported by Gelato Network (Ethereum, Polygon, Fantom, Avax and few others). Next user need to setup account which could done by calling function  ```setUpAccount(interval,amount,stableToken,dcaIntoToken) ``` on AccountManager instance. Then user has to deposit some funds on AccountManager to cover future transaction fees. Lastly user has to give approval for AutoDca contract address.
After all these steps Gellato will do the rest, it will be investing your stablecoins (or the other tokens) in a constant intervals.


