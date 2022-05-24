const Treasury = artifacts.require("Treasury");

contract(Treasury, (accounts) => {
    let treasury;

    beforeEach(async () => {
        treasury = await Treasury.new();
    });
});
