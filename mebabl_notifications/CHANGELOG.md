# Changelog

## 1.2.0

- Add device listing, quiet-hours policies, Web Push key retrieval, and browser subscription registration.
- Parse priority, category, locale, and aggregated notification counts from the backend inbox DTO.
- Expose device app version and registration timestamps.
- Explicitly reject the legacy archive API because the backend has no notification archive endpoint.

## 1.0.3

- Keep the exported `getRegisteredDeviceId()` API for restoring and revoking device registrations.
- Resolve the package analyzer's `prefer_final_locals` notice.


## 1.0.2

- Persist the server device-registration ID in secure storage after successful registration.
- Expose `getRegisteredDeviceId()` so the host app can restore push state and revoke the registration before logout.
- Clear the persisted device-registration ID after successful revocation.
- Restrict device registration to Android, iOS and web; unsupported desktop targets now return an explicit error.


## 1.0.1

- Align the inbox request with the deployed `offset` / `limit` contract and support the backend's JSON-array response.
- Parse backend category preferences and serialize the category-list update contract.
- Serialize concurrent SignalR connection attempts and clean up failed starts before retrying.
- Initialize the default Firebase app on first device registration when platform-native Firebase configuration is present.
