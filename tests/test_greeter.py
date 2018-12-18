def test_deploy(accounts, chain):
    rps, _ = chain.provider.get_or_deploy_contract('RPS')

    owner = rps.call().owner()
    assert owner == accounts[0]


# def test_custom_greeting(chain):
#     greeter, _ = chain.provider.get_or_deploy_contract('Greeter')
#
#     set_txn_hash = greeter.transact().setGreeting('Guten Tag')
#     chain.wait.for_receipt(set_txn_hash)
#
#     greeting = greeter.call().greet()
#     assert greeting == 'Guten Tag'
