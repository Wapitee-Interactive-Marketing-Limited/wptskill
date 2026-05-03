# Storefront API Advanced Patterns

## GraphQL Fragments

Define reusable fragments to keep queries DRY and compatible with Hydrogen type generation. Fragments should live near route queries or in `app/graphql` if shared across multiple routes.

```ts
export const PRODUCT_CARD_FRAGMENT = `#graphql
  fragment ProductCard on Product {
    id
    title
    handle
    vendor
    featuredImage {
      url
      altText
      width
      height
    }
    priceRange {
      minVariantPrice {
        amount
        currencyCode
      }
    }
    selectedOrFirstAvailableVariant {
      id
      availableForSale
      selectedOptions {
        name
        value
      }
    }
  }
`;

export const COLLECTION_QUERY = `#graphql
  ${PRODUCT_CARD_FRAGMENT}
  query Collection(
    $handle: String!
    $country: CountryCode
    $language: LanguageCode
    $first: Int
    $last: Int
    $startCursor: String
    $endCursor: String
  ) @inContext(country: $country, language: $language) {
    collection(handle: $handle) {
      id
      title
      products(first: $first, last: $last, before: $startCursor, after: $endCursor) {
        nodes {
          ...ProductCard
        }
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  }
`;
```

## Metafields

Query metafields directly in Storefront API. Use aliases for single metafields when the key is known, and `metafields(identifiers:)` when several fields are needed.

```graphql
query ProductWithMetafields($handle: String!) {
  product(handle: $handle) {
    id
    title
    careInstructions: metafield(namespace: "custom", key: "care_instructions") {
      value
      type
    }
    metafields(identifiers: [
      {namespace: "custom", key: "size_guide"},
      {namespace: "reviews", key: "rating"}
    ]) {
      namespace
      key
      value
      type
      reference {
        ... on MediaImage {
          image {
            url
            altText
            width
            height
          }
        }
      }
    }
  }
}
```

For rich metafield types, inspect `type` and query `reference` or `references` with inline fragments instead of parsing raw `value` strings when Storefront API can return typed data.

## Product Variants and Options

For product pages, parse selected options from the request URL and query the selected variant with `variantBySelectedOptions`. This keeps variant state shareable via URL params.

```tsx
import {getSelectedProductOptions} from '@shopify/hydrogen';
import type {Route} from './+types/products.$handle';

export async function loader({request, params, context}: Route.LoaderArgs) {
  const selectedOptions = getSelectedProductOptions(request);
  const {product} = await context.storefront.query(PRODUCT_QUERY, {
    variables: {
      handle: params.handle,
      selectedOptions,
      ...context.storefront.i18n,
    },
  });

  if (!product?.id) {
    throw new Response(null, {status: 404});
  }

  return {product};
}
```

```graphql
query Product(
  $handle: String!
  $selectedOptions: [SelectedOptionInput!]!
  $country: CountryCode
  $language: LanguageCode
) @inContext(country: $country, language: $language) {
  product(handle: $handle) {
    id
    title
    handle
    encodedVariantExistence
    encodedVariantAvailability
    options {
      name
      optionValues {
        name
        swatch {
          color
          image {
            previewImage {
              url
              altText
              width
              height
            }
          }
        }
        firstSelectableVariant {
          id
          availableForSale
          selectedOptions {
            name
            value
          }
          image {
            url
            altText
            width
            height
          }
          price {
            amount
            currencyCode
          }
        }
      }
    }
    selectedOrFirstAvailableVariant: variantBySelectedOptions(
      selectedOptions: $selectedOptions
      ignoreUnknownOptions: true
      caseInsensitiveMatch: true
    ) {
      id
      title
      availableForSale
      selectedOptions {
        name
        value
      }
      image {
        url
        altText
        width
        height
      }
      price {
        amount
        currencyCode
      }
      compareAtPrice {
        amount
        currencyCode
      }
    }
    adjacentVariants {
      id
      availableForSale
      selectedOptions {
        name
        value
      }
    }
  }
}
```

Use `getProductOptions(product)` in the component layer only after the query includes the fields above. Avoid old Hydrogen v1 hooks such as `useProductOptions`.

## Predictive Search

Predictive search is usually a resource route. Return plain objects in React Router v7.

```tsx
import type {Route} from './+types/api.predictive-search';

export async function loader({request, context}: Route.LoaderArgs) {
  const url = new URL(request.url);
  const term = url.searchParams.get('q') ?? '';
  const limit = Number(url.searchParams.get('limit') ?? 5);

  if (!term.trim()) {
    return {searchResults: null};
  }

  const {predictiveSearch} = await context.storefront.query(PREDICTIVE_SEARCH_QUERY, {
    variables: {
      query: term,
      limit,
      ...context.storefront.i18n,
    },
  });

  return {searchResults: predictiveSearch};
}
```

## Streaming Data Loading

React Router v7 removed the old `defer()` API. To stream non-critical data, start the promise without awaiting it, return the promise from the loader, and render it with `<Suspense>` and `<Await>`.

```tsx
import {Await, useLoaderData} from 'react-router';
import {Suspense} from 'react';
import type {Route} from './+types/products.$handle';

export async function loader({context}: Route.LoaderArgs) {
  const recommendations = context.storefront.query(RECOMMENDATIONS_QUERY);
  const criticalData = await context.storefront.query(CRITICAL_QUERY);

  return {
    criticalData,
    recommendations,
  };
}

export default function Page() {
  const {criticalData, recommendations} = useLoaderData<typeof loader>();

  return (
    <>
      <MainContent data={criticalData} />
      <Suspense fallback={<Skeleton />}>
        <Await resolve={recommendations}>
          {(data) => <Recommendations data={data} />}
        </Await>
      </Suspense>
    </>
  );
}
```

Only stream non-critical content. Product existence, canonical route decisions, selected variant state, and SEO-critical fields should be awaited before returning from the loader.
