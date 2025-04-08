/// A protocol for an object used to provide custom configuration for a generated GraphQL schema.
///
/// A ``SchemaConfiguration`` provides an entry point for customizing the cache key resolution
/// for the types in the schema, which is used by `NormalizedCache` mechanisms.
public protocol SchemaConfiguration {
  /// The entry point for configuring the cache key resolution
  /// for the types in the schema, which is used by `NormalizedCache` mechanisms.
  ///
  /// The default generated implementation always returns `nil`, disabling all cache normalization.
  ///
  /// Cache key resolution has a few notable quirks and limitations you should be aware of while
  /// implementing your cache key resolution function:
  ///
  /// 1. While the cache key for an object can use a field from another nested object, if the fields
  /// on the referenced object are changed in another operation, the cache key for the dependent
  /// object will not be updated. For nested objects that are not normalized with their own cache
  /// key, this will never occur, but if the nested object is an entity with its own cache key, it
  /// can be mutated independently. In that case, any other objects whose cache keys are dependent
  /// on the mutated entity will not be updated automatically. You must take care to update those
  /// entities manually with a cache mutation.
  ///
  /// 2. The `object` passed to this function represents data for an object in an specific operation
  /// model, not a type in your schema. This means that
  /// [aliased fields](https://spec.graphql.org/draft/#sec-Field-Alias) will be keyed on their
  /// alias name, not the name of the field on the schema type.
  ///
  /// 3. The `object` parameter of this function is an ``ObjectData`` struct that wraps the
  /// underlying object data. Because cache key resolution is performed both on raw JSON (from a
  /// network response) and `SelectionSet` model data (when writing to the cache directly),
  /// the underlying data will have different formats. The ``ObjectData`` wrapper is used to
  /// normalize this data to a consistent format in this context.
  ///
  /// # See Also
  /// ``CacheKeyInfo``
  ///
  /// - Parameters:
  ///   - type: The ``Object`` type of the response `object`.
  ///   - object: The response object to resolve the cache key for.
  ///     Represented as a ``ObjectData`` dictionary.
  /// - Returns: A ``CacheKeyInfo`` describing the computed cache key for the response object.
  static func cacheKeyInfo(for type: Object, object: ObjectData) -> CacheKeyInfo?

  /// Provides metadata for resolving a GraphQL operation by directly reading a single object
  /// from the normalized cache using its canonical cache key.
  ///
  /// This enables cache hits for operations that haven't been executed before,
  /// as long as the required object data already exists in the cache (e.g., resolving
  /// `getOrder(id: "123")` after a previous `getOrders()` call).
  ///
  /// - Parameters:
  ///   - operation: The type of the operation being executed.
  ///   - variables: The runtime variables associated with the operation.
  /// - Returns: ``CacheResolverInfo`` if custom cache resolution should be attempted, otherwise `nil`.
  static func cacheResolverInfo<Operation: GraphQLOperation>( for operation: Operation.Type, variables: Operation.Variables?) -> CacheResolverInfo?
}

/// Describes how to resolve a query operation by directly reading a normalized object
/// from the cache using its canonical cache key.
public struct CacheResolverInfo {
    /// The canonical cache key of the target object (e.g., "Order:123").
    /// This key must match the value computed by `SchemaConfiguration.cacheKeyInfo(...)`.
    public let cacheKey: String

    /// The type of root-level selection set used to read and interpret the object at `cacheKey`.
    /// This type defines the structure of the object that will be read from the cache,
    /// and must include all fields necessary to satisfy the query being resolved.
    ///
    /// As an example, if your query returns an `Order` object with a fragment like:
    /// ```graphql
    /// fragment OrderFragment on Order {
    ///   id
    ///   status
    ///   total
    /// }
    ///
    /// query GetOrder {
    ///   order { ...OrderFragment }
    /// }
    /// ```
    /// then `rootSelectionSetType` should be `OrderFragment.self`.
    ///
    /// The resolved object will be wrapped under `rootFieldKey` (if provided) to synthesize
    /// a `GraphQLResult` compatible with the operation’s expected `Data` type.
    public let rootSelectionSetType: RootSelectionSet.Type

    /// The name of the top-level field in the operation’s `Data` structure where the resolved object should be placed.
    ///
    /// For example, in a query like:
    /// ```graphql
    /// query GetOrder {
    ///   order { ...OrderFragment }
    /// }
    /// ```
    /// the corresponding field in the generated `Data` type would be `order`,
    /// so `rootFieldKey` should be set to `"order"`.
    ///
    /// If this value is `nil`, the resolved object is treated as the root of the response.
    public let rootFieldKey: String?
    
    
    public init(
        cacheKey: String,
        rootSelectionSetType: RootSelectionSet.Type,
        rootFieldKey: String? = nil
    ) {
        self.cacheKey = cacheKey
        self.rootSelectionSetType = rootSelectionSetType
        self.rootFieldKey = rootFieldKey
    }
}


public extension SchemaConfiguration {
    static func cacheResolverInfo<Operation: GraphQLOperation>(
        for operation: Operation.Type,
        variables: Operation.Variables?
    ) -> CacheResolverInfo? {
        return nil // Default: no custom resolution
    }
}
