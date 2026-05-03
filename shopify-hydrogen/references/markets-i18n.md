# Hydrogen Markets and Internationalization

## Storefront i18n Context

Hydrogen storefront clients expose `context.storefront.i18n`, usually shaped like `{country: 'US', language: 'EN'}`. Pass this object to Storefront API queries that render product, collection, price, availability, or localized content.

```graphql
query Product($handle: String!, $country: CountryCode, $language: LanguageCode)
@inContext(country: $country, language: $language) {
  product(handle: $handle) {
    title
    description
    priceRange {
      minVariantPrice {
        amount
        currencyCode
      }
    }
  }
}
```

```tsx
export async function loader({params, context}: Route.LoaderArgs) {
  const {product} = await context.storefront.query(PRODUCT_QUERY, {
    variables: {
      handle: params.handle,
      ...context.storefront.i18n,
    },
  });

  if (!product?.id) {
    throw new Response(null, {status: 404});
  }

  return {product};
}
```

## URL-Based Locale Detection

Hydrogen projects commonly use optional locale prefixes such as `/en-us/products/shirt` and `/fr-fr/products/shirt`. Configure the locale before creating the Hydrogen context so every route receives the correct Storefront API client i18n values.

```ts
const hydrogenContext = createHydrogenContext({
  env,
  request,
  cache,
  waitUntil,
  session,
  i18n: getLocaleFromRequest(request),
});
```

The locale parser should validate incoming URL segments and fall back to a supported default.

```ts
const SUPPORTED_LOCALES = {
  'en-us': {language: 'EN', country: 'US'},
  'fr-fr': {language: 'FR', country: 'FR'},
} as const;

export function getLocaleFromRequest(request: Request) {
  const {pathname} = new URL(request.url);
  const maybeLocale = pathname.split('/')[1]?.toLowerCase();

  return SUPPORTED_LOCALES[maybeLocale as keyof typeof SUPPORTED_LOCALES] ?? {
    language: 'EN',
    country: 'US',
  };
}
```

## Locale Routes

Use an optional `$locale` route segment when the same route should handle both localized and non-localized URLs.

```
app/routes/
  ($locale)._index.tsx
  ($locale).products.$handle.tsx
  ($locale).collections.$handle.tsx
```

Validate route params and redirect unsupported locale prefixes instead of silently rendering the wrong market.

```tsx
import {redirect} from 'react-router';

export async function loader({params}: Route.LoaderArgs) {
  if (params.locale && !isSupportedLocale(params.locale)) {
    throw redirect('/');
  }

  return {};
}
```

## Market-Aware Cart

Cart operations are market-aware when the cart buyer identity and Storefront API i18n context match the buyer's market. In current Hydrogen projects, prefer the cart handler created by `createHydrogenContext`; pass `buyerIdentity` there when you need to seed cart creation with a specific country, customer token, company location, or delivery context.

```ts
const hydrogenContext = createHydrogenContext({
  env,
  request,
  cache,
  waitUntil,
  session,
  i18n: getLocaleFromRequest(request),
  buyerIdentity: {
    countryCode: getLocaleFromRequest(request).country,
  },
});
```

When a cart already exists and the shopper changes market, update the cart buyer identity.

```tsx
import {CartForm} from '@shopify/hydrogen';
import type {CountryCode} from '@shopify/hydrogen/storefront-api-types';

export function MarketSwitcherCartIdentity({countryCode}: {countryCode: CountryCode}) {
  return (
    <CartForm
      route="/cart"
      action={CartForm.ACTIONS.BuyerIdentityUpdate}
      inputs={{
        buyerIdentity: {
          countryCode,
        },
      }}
    >
      <button type="submit">Update market</button>
    </CartForm>
  );
}
```

The cart route action should handle `CartForm.ACTIONS.BuyerIdentityUpdate` with `cart.updateBuyerIdentity(inputs.buyerIdentity)`.

## Localized Handles

Product and collection handles can be localized by Storefront API. If a product is found by a non-canonical handle, redirect to the localized handle rather than rendering duplicate URLs.

```tsx
import {redirect} from 'react-router';

function redirectIfHandleIsLocalized(request: Request, handle: string, localizedHandle?: string) {
  if (!localizedHandle || localizedHandle === handle) return;

  const url = new URL(request.url);
  url.pathname = url.pathname.replace(`/products/${handle}`, `/products/${localizedHandle}`);

  throw redirect(url.pathname + url.search);
}
```

## SEO and hreflang

For localized storefronts, make canonical URLs market-aware and include alternate URLs when the project has a stable locale map. Keep this logic in `meta` exports or a shared SEO helper rather than hardcoding tags in `root.tsx`.

```tsx
export const meta: Route.MetaFunction = ({data}) => {
  return getSeoMeta({
    title: data?.seo.title,
    description: data?.seo.description,
    url: data?.canonicalUrl,
    alternates: data?.alternateUrls,
  });
};
```
