/// This handles fetching user data and login histories from the Vercel Users API,
/// including automatic retry logic for handling API unreliability. It also provides
/// IP geolocation services for looking up country codes.
///
/// ## Usage
///
/// ```swift
/// // Fetch users with login histories
/// let userService = LiveUserService()
/// for await event in userService.streamUsers() {
///     // Handle user stream events
/// }
///
/// // Lookup country code for an IP address
/// let geoService = LiveGeolocationService()
/// let countryCode = try await geoService.fetchCountryCode(for: "8.8.8.8")
/// ```
///
/// ## Error Handling
///
/// The SDK uses `APIError` to represent failures. All errors conform to `LocalizedError`
/// for easy presentation to users.
public struct SitewireUserSDK {
    /// The current version of the SDK
    public static let version = "1.0.0"
}
