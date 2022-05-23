// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibTransformERC20RichErrors {
    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(
                    keccak256("TransformerFailedError(address,bytes,bytes)")
                ),
                transformer,
                transformerData,
                resultData
            );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
                errorCode,
                transformData
            );
    }
}
