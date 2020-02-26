pragma solidity ^0.5.14;

contract PackageLabels {
    uint256 public packageLabelCount = 0;

    struct PackageLabel {
        string batchId;
        uint256 batchSize;
        string labelCertificateLocation;
    }

    mapping(string => PackageLabel) public packageLabels;

  event PackageLabelBatchCreatedEvent(
        string batchId,
        uint256 batchSize,
        string labelCertificateLocation
  );

    function registerPackageLabel(string memory batchId, uint256 batchSize, string memory labelCertificateLocation)
        public
    {
        require(batchSize > 0, "batch size must be > 0 when registering a batch of labels");
        require(bytes(batchId).length > 0, "batchId must contain a valid string when registering a batch of labels");
        packageLabels[batchId] = PackageLabel(batchId, batchSize, labelCertificateLocation);
        emit PackageLabelBatchCreatedEvent(batchId, batchSize, labelCertificateLocation);
    }

    function getPackageLabelBatchSize(string memory batchId)
        public
        view
        returns (uint256 batchSize)
    {
        require(bytes(batchId).length > 0, "batchId must contain a valid string when getting the size of a batch");
        PackageLabel memory label = packageLabels[batchId];
        return label.batchSize;
    }
    
    function getPackageLabelCertificateLocation(string memory batchId)
        public
        view
        returns (string memory labelCertificateLocation)
    {
        require(bytes(batchId).length > 0, "batchId must contain a valid string when getting the size of a batch");
        PackageLabel memory label = packageLabels[batchId];
        return label.labelCertificateLocation;
    }

    function uploadPackageLabelCertificate(string memory batchId, string memory labelCertificateLocation)
        public
    {
        require(bytes(batchId).length > 0, "batchId must contain a valid string");
        require(bytes(packageLabels[batchId].batchId).length > 0, "batch for batchId must exist, i.e. must be previously registered");
        require(bytes(labelCertificateLocation).length > 0, "storage location for the labels certificate must contain a string value");
        packageLabels[batchId].labelCertificateLocation = labelCertificateLocation;
    }
}
