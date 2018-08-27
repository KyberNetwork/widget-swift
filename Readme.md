# KyberWidget iOS Library
The KyberWidget iOS lib allows developers to easily add crytocurrency payment and swapping features to iOS apps.

## What does it do

The library enables 2 use cases:

- **Payment**: allow users to buy goods or services from within your app,  paying with any tokens supported by KyberNetwork
- **Swap**: Allow users to swap between token pairs supported by KyberNetowrk

The lib shipped with a standard, ready-to-use UI. It also let developers to customize many aspects of UI to fit their needs.

## How to add KyberWidget into your project.

Currently you have to manually add KyberWidget into your project ([Cocoapods](https://cocoapods.org/) will be available soon).

Download the library in this repo [here](https://github.com/KyberNetwork/widget-swift/KyberWidget/KyberWidget.framework) and add it into your project. 

Go to your project General settings, add KyberWidget into Embedded Binaries.

## Usage

#### Import KyberWidget

```swift
import KyberWidget
```

#### Define KWCoodinator instance

```swift
fileprivate var coordinator: KWCoordinator?
```

#### Create KWCoordinator instance

First, you need to create and intialize the `KWCoordinator` instance.

**NOTE** To use the widget for _swap_ use case, pass "self" (literally) as value for `receiverAddress` parameter. Otherwise, it will displayed as a _payment_ widget.

```swift
self.coordinator = KWCoordinator(
  baseViewController: UIViewController,
  receiveAddr: String,
  receiveToken: String?,
  receiveAmount: Double?,
  network: String? // ETH network ("ropsten", "mainnet"),
  signer: String?,
  commissionID: String?
)
```
***Parameter details:***

- ***receiveAddr*** (ethereum address with 0x prefix) - **required** - For _payment_ use case, this is the vendor's Ethereum wallet which user's payment will be sent there. *Must double check this param very carefully*. For _swap_ use case, please set this parameter as *self*

- ***receiveToken*** (string) - **required for _payment_ use case** - token that you (vendor) want to receive, it can be one of supported tokens (such as ETH, DAI, KNC...).

- ***receiveAmount*** (float) - the amount of `receiveToken` you (vendor) want your user to pay. If you leave it blank or missing, the users can specify it in the widget interface. It could be useful for undetermined payment or pay-as-you-go payment like a charity, ICO or anything else. This param is ignored if you do not specify `receiveToken`.

- ***network*** (string) - default: `ropsten`, ethereum network that the widget will run. Possible value: `test, ropsten, production, mainnet`.

- ***signer*** (string) - concatenation of a list of ethereum address by underscore `_`, eg. 0xFDF28Bf25779ED4cA74e958d54653260af604C20_0xFDF28Bf25779ED4cA74e958d54653260af604C20 - If you pass this param, the user will be forced to pay from one of those addresses.

- ***commissionID*** - Ethereum address - your Ethereum wallet to get commission of the fees for the transaction. Your wallet must be whitelisted by KyberNetwork (the permissionless registration will be available soon) in order to get the commission, otherwise it will be ignored.

If you want to customize the widget UI, please check _Customize color theme and string_ section later on this page.

After that, set `delegate` and show the widget.

```swift
// set delegate to receive transaction data
self.coordinator?.delegate = self

// show the widget
self.coordinator?.start()
```

#### Delegation - KWCoordinatorDelegate

The delegate class should implement the following 3 functions.

```swift
func coordinatorDidCancel() {
  // TODO: handle user cancellation
}
```
This function is called when user cancelled the action.

```swift
func coordinatorDidFailed(with error: KWError) {
  // TODO: handle errors
}
```
This function is called when something went wrong, some possible errors: 
- **unsupportedToken**: your token you set is not supported by Kyber.
- **invalidAddress**: your receiver address is not a valid ETH address.
- **invalidAmount**: your amount you set is not a valid amount.
- **failedToLoadSupportedToken(errorMessage: String)**: something went wrong and we could not load supported tokens by Kyber.
- **failedToSendPayment(errorMessage: String)**: Could not send payment request.

```swift
func coordinatorDidBroadcastTransaction(with txHash: String) {
  // TODO: poll blockchain to check for transaction's status and validity
}
```
This function is called when the transaction was broadcasted to Ethereum network. [Read here](https://github.com/KyberNetwork/KyberWidget/blob/master/README.md#how-to-get-payment-status) for How to check and confirm payment status.


### Customize color theme and string
#### Theme

Get current KWThemeConfig intance.
```swift
let config = KWThemeConfig.current
```
From here you could config the color by your own choice. Go to *KWThemeConfig* class to see all available attributes that you could change the color.

#### String

Similar to `KWThemeConfig`, using `KWStringConfig` to config the string.

```swift
let config = KWStringConfig.current
config.youAreAboutToPay = "You are going to buy"
```

The string *You are about to pay* should be changed to *You are going to buy*

### Create your own UIs

You could also create your own UIs and use our helper functions to get list of supported tokens, get expected rate between tokens, get balance of ETH/token given the address, sign the transaction and send transfer/trade functions.

**Supported Tokens**

To get Kyber supported tokens, call:
`KWSupportedToken.shared.fetchTrackerSupportedTokens(network: KWEnvironment, completion: @escaping (Result<[KWTokenObject], AnyError>) -> Void)`

Return list of supported tokens by Kyber or error otherwise.

**Current gas price**

Get current fast/standard/slow gas price using our server cache

`func performFetchRequest(service: KWNetworkProvider, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void)`
Use **_KWNetworkProvider.gasGasPrice_** as service.

**Keystore**

Create a KWKeystore instance to help import wallet, get current account, sign transaction, etc

`let keystore = try KWKeystore()`

Available functions in KWKeystore:
 `var accounts: [Account] {}` list of accounts imported
`var account: Account? {}` return first imported account
`func removeAllAccounts(completion: @escaping () -> Void) {}` remove all imported accounts
`func importWallet(type: KWImportType, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {}` import an account of **KWImportType** (Check this file)
`func delete(account: Account, completion: @escaping (Result<Void, KWKeystoreError>) -> Void) {}` delete an account
`func signTransaction(transaction: KWDraftTransaction) -> Result<Data, KWKeystoreError> {}` sign a transaction

**External Provider**

`let externalProvider = KWExternalProvider(keystore: keystore, network: network)`: init **_KWExternalProvider_** with an instance of keystore and network.

External Provider provides all functions needed to perform a payment, or to use KyberSwap.

Some useful functions:
`func getETHBalance(address: String, completion: @escaping (Result<BigInt, AnyError>) -> Void)`
`func getTokenBalance(for contract: Address, address: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void)`
`func getTransactionCount(for address: String, completion: @escaping (Result<Int, AnyError>) -> Void)`
`func transfer(transaction: KWPayment, completion: @escaping (Result<String, AnyError>) -> Void)`
`func exchange(exchange: KWPayment, completion: @escaping (Result<String, AnyError>) -> Void)`
`func getAllowance(token: KWTokenObject, address: Address, completion: @escaping (Result<Bool, AnyError>) -> Void)`
`func sendApproveERC20Token(exchangeTransaction: KWPayment, completion: @escaping (Result<Bool, AnyError>) -> Void)`
`func getExpectedRate(from: KWTokenObject, to: KWTokenObject, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void)`
`func getTransferEstimateGasLimit(for transaction: KWPayment, completion: @escaping (Result<BigInt, AnyError>) -> Void)`
`func getSwapEstimateGasLimit(for transaction: KWPayment, completion: @escaping (Result<BigInt, AnyError>) -> Void)`
`func estimateGasLimit(from: String, to: String?, gasPrice: BigInt, value: BigInt, data: Data, defaultGasLimit: BigInt, completion: @escaping (Result<BigInt, AnyError>) -> Void)`

## Supported tokens
See all supported tokens [here](https://tracker.kyber.network/#/tokens)
