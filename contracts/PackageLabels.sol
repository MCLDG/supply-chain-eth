pragma solidity ^0.5.14;

contract PackageLabels {
    uint256 public packageLabelCount = 0;

    struct PackageLabel {
        string batchId;
        uint256 batchSize;
        string labelCertificateHashIPFS;
        string labelCertificateLocationStorage;
    }

    mapping(string => PackageLabel) public packageLabels;

    event PackageLabelBatchEvent(
        string batchId,
        uint256 batchSize,
        string labelCertificateHashIPFS,
        string labelCertificateLocationStorage
    );

    function registerPackageLabel(string memory batchId, uint256 batchSize)
        public
    {
        require(
            batchSize > 0,
            "batch size must be > 0 when registering a batch of labels"
        );
        require(
            bytes(batchId).length > 0,
            "batchId must contain a valid string when registering a batch of labels"
        );
        packageLabels[batchId] = PackageLabel(batchId, batchSize, "", "");
        packageLabelCount++;
        emit PackageLabelBatchEvent(batchId, batchSize, "", "");
    }

    function getPackageLabelBatchSize(string memory batchId)
        public
        view
        returns (uint256 batchSize)
    {
        require(
            bytes(batchId).length > 0,
            "batchId must contain a valid string when getting the size of a batch"
        );
        PackageLabel memory label = packageLabels[batchId];
        return label.batchSize;
    }

    function getPackageLabelCertificateHashIPFS(string memory batchId)
        public
        view
        returns (string memory labelCertificateHashIPFS)
    {
        require(
            bytes(batchId).length > 0,
            "batchId must contain a valid string when getting the size of a batch"
        );
        PackageLabel memory label = packageLabels[batchId];
        return label.labelCertificateHashIPFS;
    }

    function uploadPackageLabelCertificateIPFS(
        string memory batchId,
        string memory labelCertificateHashIPFS
    ) public {
        require(
            bytes(batchId).length > 0,
            "batchId must contain a valid string"
        );
        require(
            bytes(packageLabels[batchId].batchId).length > 0,
            "batch for batchId must exist, i.e. must have been previously registered"
        );
        require(
            bytes(labelCertificateHashIPFS).length > 0,
            "the labels certificate must contain a string value representing an IPFS hash"
        );
        packageLabels[batchId]
            .labelCertificateHashIPFS = labelCertificateHashIPFS;
    }
}
