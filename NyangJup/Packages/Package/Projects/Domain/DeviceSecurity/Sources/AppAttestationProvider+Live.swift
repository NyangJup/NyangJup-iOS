import DeviceCheck
import Foundation

import DomainDeviceSecurityInterface

public extension AppAttestationProvider {
    static let live = Self(
        isSupported: {
            DCAppAttestService.shared.isSupported
        },
        generateKey: {
            try await withCheckedThrowingContinuation { continuation in
                DCAppAttestService.shared.generateKey { keyId, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let keyId {
                        continuation.resume(returning: keyId)
                    } else {
                        continuation.resume(throwing: DeviceSecurityError.appAttestUnsupported)
                    }
                }
            }
        },
        attestKey: { keyId, clientDataHash in
            try await withCheckedThrowingContinuation { continuation in
                DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash) { data, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: DeviceSecurityError.appAttestUnsupported)
                    }
                }
            }
        },
        generateAssertion: { keyId, clientDataHash in
            try await withCheckedThrowingContinuation { continuation in
                DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) { data, error in
                    if let error {
                        if let error = error as? DCError, error.code == .invalidKey {
                            continuation.resume(throwing: DeviceSecurityError.invalidAppAttestKey)
                        } else {
                            continuation.resume(throwing: error)
                        }
                    } else if let data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: DeviceSecurityError.appAttestUnsupported)
                    }
                }
            }
        }
    )
}
