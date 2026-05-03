---
name: shopify-hydrogen
description: "Expert guidance for developing Shopify headless storefronts with Hydrogen (2026+). Use for: building Hydrogen projects, querying Storefront API, implementing cart/auth/SEO, avoiding Next.js mental model mistakes, and following correct React Router v7 architecture patterns."
---

# Shopify Hydrogen Development

This skill provides authoritative guidance for building Shopify Hydrogen storefronts. Hydrogen 2026 is built on **React Router v7** and deployed on Shopify's **Oxygen** edge runtime. It is NOT Next.js. Do not apply Next.js App Router, Server Component, Server Action, or middleware patterns.

## Core Architecture

The Hydrogen stack has three layers:

| Layer | Role |
|-------|------|
| **Hydrogen** (`@shopify/hydrogen`) | Shopify-specific components, utilities, analytics, cart, and Storefront API client |
| **React Router v7** | Route modules, SSR, data loading (`loader`), mutations (`action`), metadata (`meta`) |
| **Oxygen** | Shopify-hosted edge runtime for deployment |

**Project structure** (default skeleton):
```
hydrogen-project/
├── app/
│   ├── components/
│   ├── graphql/
│   ├── lib/
│   ├── routes/              # route modules: loader/action/meta/default export
│   ├── entry.client.tsx
│   ├── entry.server.tsx
│   └── root.tsx
├── public/
├── server.ts                # createHydrogenContext + request handler
├── react-router.config.ts
├── vite.config.ts
└── .env                     # PUBLIC_STOREFRONT_API_TOKEN, SESSION_SECRET, etc.
```

## React Router v7 Rules

- Import route helpers and hooks from `react-router`, not `@remix-run/react`.
- Do not use the old `json()` or `defer()` APIs in new Hydrogen 2026 examples. Return plain objects from loaders/actions, or use `data()` from `react-router` when you need status/headers.
- For streaming/deferred data, return unresolved promises from the loader and render them with `<Suspense>` and `<Await>`.
- In TypeScript route files, prefer generated route types: `import type {Route} from './+types/<route-file>';`.

```tsx
import {useLoaderData} from 'react-router';
import type {Route} from './+types/products.$handle';

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

export default function ProductPage() {
  const {product} = useLoaderData<typeof loader>();
  return <h1>{product.title}</h1>;
}
```

## Key Differences from Next.js

| Concept | Next.js App Router | Hydrogen / React Router v7 |
|---------|--------------------|-----------------------------|
| Data fetching | `async` Server Components, `fetch` | `loader({context, params, request})` |
| Mutations | Server Actions | `action({request, context})` |
| Forms | `<form action={serverAction}>` | `<Form method="post">` or `<CartForm>` |
| Head/Meta | `export const metadata` | `export const meta = ({data, matches}) => [...]` |
| Images | `next/image` | `<Image data={image} aspectRatio="1/1" />` |
| Auth | NextAuth / middleware | Customer Account API client + OAuth routes |

## Server Context

Use `createHydrogenContext` once in `server.ts`, then pass the context to React Router. Keep session commits centralized in the server response handling.

```ts
import {createHydrogenContext, storefrontRedirect} from '@shopify/hydrogen';
import {createRequestHandler} from '@shopify/hydrogen/oxygen';
import * as reactRouterBuild from 'virtual:react-router/server-build';
import {AppSession} from '~/lib/session';

export default {
  async fetch(request: Request, env: Env, executionContext: ExecutionContext) {
    const waitUntil = executionContext.waitUntil.bind(executionContext);
    const [cache, session] = await Promise.all([
      caches.open('hydrogen'),
      AppSession.init(request, [env.SESSION_SECRET]),
    ]);

    const hydrogenContext = createHydrogenContext({
      env,
      request,
      cache,
      waitUntil,
      session,
    });

    const handleRequest = createRequestHandler({
      build: reactRouterBuild,
      mode: process.env.NODE_ENV,
      getLoadContext: () => hydrogenContext,
    });

    const response = await handleRequest(request);

    if (session.isPending) {
      response.headers.set('Set-Cookie', await session.commit());
    }

    return storefrontRedirect({
      request,
      response,
      storefront: hydrogenContext.storefront,
    });
  },
};
```

## Storefront API Data Fetching

Use `context.storefront.query()` inside `loader` functions. Always use the `#graphql` tag and include `@inContext` for buyer market and language when data can vary by country or locale.

```tsx
import {useLoaderData} from 'react-router';
import type {Route} from './+types/products.$handle';

const PRODUCT_QUERY = `#graphql
  query Product($handle: String!, $country: CountryCode, $language: LanguageCode)
  @inContext(country: $country, language: $language) {
    product(handle: $handle) {
      id
      title
      description
      featuredImage { url altText width height }
      priceRange { minVariantPrice { amount currencyCode } }
    }
  }
`;

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

export default function ProductPage() {
  const {product} = useLoaderData<typeof loader>();
  return <h1>{product.title}</h1>;
}
```

## Product Variants

For selected variants, use `getSelectedProductOptions(request)` in the loader and pass the result to `variantBySelectedOptions`. For rendering product option buttons, use `getProductOptions()` with the fields required by the current Hydrogen product option model.

```tsx
import {
  getAdjacentAndFirstAvailableVariants,
  getProductOptions,
  getSelectedProductOptions,
  useOptimisticVariant,
  useSelectedOptionInUrlParam,
} from '@shopify/hydrogen';
import {useLoaderData} from 'react-router';

export async function loader({request, params, context}: Route.LoaderArgs) {
  const {product} = await context.storefront.query(PRODUCT_QUERY, {
    variables: {
      handle: params.handle,
      selectedOptions: getSelectedProductOptions(request),
    },
  });

  if (!product?.id) {
    throw new Response(null, {status: 404});
  }

  return {product};
}

export default function Product() {
  const {product} = useLoaderData<typeof loader>();
  const selectedVariant = useOptimisticVariant(
    product.selectedOrFirstAvailableVariant,
    getAdjacentAndFirstAvailableVariants(product),
  );

  useSelectedOptionInUrlParam(selectedVariant.selectedOptions);

  const productOptions = getProductOptions({
    ...product,
    selectedOrFirstAvailableVariant: selectedVariant,
  });

  return <ProductForm productOptions={productOptions} selectedVariant={selectedVariant} />;
}
```

Query the fields needed by `getProductOptions`: `handle`, `encodedVariantExistence`, `encodedVariantAvailability`, `options { name optionValues { name firstSelectableVariant { ... } swatch { ... } } }`, `selectedOrFirstAvailableVariant`, and `adjacentVariants`.

## Pagination

Use `getPaginationVariables` plus `<Pagination>`. Do not manually manage cursor state.

```tsx
import {getPaginationVariables, Pagination} from '@shopify/hydrogen';
import {Link, useLoaderData} from 'react-router';

export async function loader({request, context}: Route.LoaderArgs) {
  const variables = getPaginationVariables(request, {pageBy: 8});
  const {products} = await context.storefront.query(PRODUCTS_QUERY, {
    variables: {
      ...variables,
      ...context.storefront.i18n,
    },
  });

  return {products};
}

export default function CollectionPage() {
  const {products} = useLoaderData<typeof loader>();

  return (
    <Pagination connection={products}>
      {({nodes, NextLink, PreviousLink, isLoading}) => (
        <>
          <PreviousLink>{isLoading ? 'Loading...' : 'Load previous'}</PreviousLink>
          {nodes.map((product) => (
            <Link key={product.id} to={`/products/${product.handle}`}>
              {product.title}
            </Link>
          ))}
          <NextLink>{isLoading ? 'Loading...' : 'Load more'}</NextLink>
        </>
      )}
    </Pagination>
  );
}
```

The GraphQL query must accept `first`, `last`, `startCursor`, and `endCursor`, then pass them as `products(first: $first, last: $last, before: $startCursor, after: $endCursor)`. The connection must include `pageInfo { hasPreviousPage hasNextPage startCursor endCursor }`.

## Cart Operations

Use `<CartForm>` for cart mutations and `context.cart` in the cart route action. Do not build a separate cart state manager unless the project has a very specific custom cart requirement.

```tsx
import {CartForm} from '@shopify/hydrogen';
import {data} from 'react-router';
import invariant from 'tiny-invariant';

export function AddToCartButton({variantId, quantity = 1}) {
  return (
    <CartForm
      route="/cart"
      action={CartForm.ACTIONS.LinesAdd}
      inputs={{lines: [{merchandiseId: variantId, quantity}]}}
    >
      <button type="submit">Add to cart</button>
    </CartForm>
  );
}

export async function action({request, context}: Route.ActionArgs) {
  const {cart} = context;
  const formData = await request.formData();
  const {action, inputs} = CartForm.getFormInput(formData);

  let result;

  switch (action) {
    case CartForm.ACTIONS.LinesAdd:
      result = await cart.addLines(inputs.lines);
      break;
    case CartForm.ACTIONS.LinesUpdate:
      result = await cart.updateLines(inputs.lines);
      break;
    case CartForm.ACTIONS.LinesRemove:
      result = await cart.removeLines(inputs.lineIds);
      break;
    default:
      invariant(false, `${action} cart action is not defined`);
  }

  const headers = cart.setCartId(result.cart.id);
  return data(result, {status: 200, headers});
}
```

## Built-in Components

| Component | Usage | Key Props |
|-----------|-------|-----------|
| `<Image>` | Render Storefront API images | `data`, `aspectRatio`, `sizes` |
| `<Money>` | Format money values | `data`, `withoutTrailingZeros` |
| `<CartForm>` | Submit cart mutations | `action`, `inputs`, `route` |
| `<Pagination>` | Cursor-based pagination | `connection` |
| `<MediaFile>` | Render product media | `data` |
| `<Analytics.Provider>` | Shopify analytics and consent | `cart`, `shop`, `consent` |

`Image`, `Video`, `ExternalVideo`, `MediaFile`, and `Money` are Hydrogen React components that render Storefront API data. They are not GraphQL types and should not be treated as Storefront API operations.

```tsx
import {Image} from '@shopify/hydrogen';

export function ProductImage({image}) {
  if (!image) return null;

  return (
    <Image
      data={image}
      aspectRatio="4/5"
      sizes="(min-width: 45em) 50vw, 100vw"
    />
  );
}
```

## Customer Authentication

Hydrogen uses the OAuth-based Customer Account API. Legacy customer access tokens and Multipass are not the current Hydrogen auth model.

Customer Account API authentication does not support `localhost`. For local development, use a public HTTPS domain such as ngrok or Hydrogen CLI tunneling, then register the callback and logout URLs in Shopify admin.

```bash
ngrok http --domain=<your-ngrok-domain> 3000
npx shopify hydrogen link
npx shopify hydrogen env pull
```

Required environment variables:

| Variable | Description |
|----------|-------------|
| `PUBLIC_CUSTOMER_ACCOUNT_API_CLIENT_ID` | Customer Account API client ID |
| `PUBLIC_CUSTOMER_ACCOUNT_API_URL` | Customer Account API URL, when required by the template |
| `SHOP_ID` | Shop GID |
| `SESSION_SECRET` | Secret used by session storage |

Auth routes:

`app/routes/account_.login.tsx`

```tsx
export async function loader({context}: Route.LoaderArgs) {
  return context.customerAccount.login();
}
```

`app/routes/account_.authorize.tsx`

```tsx
export async function loader({context}: Route.LoaderArgs) {
  return context.customerAccount.authorize();
}
```

`app/routes/account_.logout.tsx`

```tsx
export async function action({context}: Route.ActionArgs) {
  return context.customerAccount.logout();
}
```

For ngrok or another custom HTTPS domain, add the domain to the Customer Account API callback URI with `/account/authorize`, add the JavaScript origin and logout URI, and allow the tunnel websocket host in the Content Security Policy `connect-src`.

## Analytics

Hydrogen analytics belongs in the root route. Use `getShopAnalytics` in the root loader and wrap the app with `Analytics.Provider`.

```tsx
import {Analytics, getShopAnalytics} from '@shopify/hydrogen';
import {Outlet, useLoaderData} from 'react-router';

export async function loader({context}: Route.LoaderArgs) {
  const {cart, env, storefront} = context;

  return {
    cart: cart.get(),
    shop: getShopAnalytics({
      storefront,
      publicStorefrontId: env.PUBLIC_STOREFRONT_ID,
    }),
    consent: {
      checkoutDomain: env.PUBLIC_CHECKOUT_DOMAIN,
      storefrontAccessToken: env.PUBLIC_STOREFRONT_API_TOKEN,
      withPrivacyBanner: true,
      country: storefront.i18n.country,
      language: storefront.i18n.language,
    },
  };
}

export default function App() {
  const data = useLoaderData<typeof loader>();

  return (
    <Analytics.Provider cart={data.cart} shop={data.shop} consent={data.consent}>
      <Outlet />
    </Analytics.Provider>
  );
}
```

## SEO

Use `getSeoMeta` with React Router's `meta` export. Do not use Next.js metadata, `<Helmet>`, or custom `<Head>` components.

```tsx
import {getSeoMeta} from '@shopify/hydrogen';
import type {Route} from './+types/products.$handle';

export async function loader({context, params}: Route.LoaderArgs) {
  const {product} = await context.storefront.query(PRODUCT_QUERY, {
    variables: {handle: params.handle},
  });

  return {
    seo: {
      title: product.seo?.title ?? product.title,
      description: product.seo?.description ?? product.description,
    },
  };
}

export const meta: Route.MetaFunction = ({data, matches}) => {
  return getSeoMeta(...matches.map((match) => match.data?.seo));
};
```

Generate sitemap and robots.txt when needed:

```bash
npx shopify hydrogen generate route sitemap
npx shopify hydrogen generate route robots
```

## Caching

Hydrogen provides granular caching via `CacheShort`, `CacheLong`, `CacheNone`, and `CacheCustom`.

```tsx
import {CacheNone, CacheShort} from '@shopify/hydrogen';

const {products} = await context.storefront.query(PRODUCTS_QUERY, {
  cache: CacheShort(),
});

const privateBuyerData = await context.storefront.query(PRIVATE_BUYER_QUERY, {
  cache: CacheNone(),
});
```

Never apply `CacheLong` to customer-specific data, cart data, or any response that varies by session, customer, or private buyer identity. Customer Account API queries are authenticated per customer and should not be treated as shared Storefront API cache entries.

## Common Pitfalls

1. **Using `useEffect` plus `fetch` for route data**: Use `loader` for SSR-first data.
2. **Importing from `@remix-run/react` in new code**: Use `react-router`.
3. **Returning `json()` or `defer()` from new loaders**: Return plain objects or promises; use `data()` when status or headers are required.
4. **Manually building pagination**: Use `getPaginationVariables` and `<Pagination>`.
5. **Custom cart state management**: Use `<CartForm>` and `createHydrogenContext` cart utilities.
6. **Testing Customer Account API on localhost**: Use HTTPS tunneling and registered OAuth URLs.
7. **Missing `aspectRatio` on `<Image>`**: This can cause layout shift.
8. **Caching private data**: Configure caching per query and avoid caching cart/customer results.

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `PUBLIC_STORE_DOMAIN` | Yes | Store domain, for example `mystore.myshopify.com` |
| `PUBLIC_STOREFRONT_API_TOKEN` | Yes | Public Storefront API token |
| `PRIVATE_STOREFRONT_API_TOKEN` | Recommended | Private token for server-side Storefront API queries |
| `PUBLIC_STOREFRONT_ID` | Yes | Hydrogen storefront ID |
| `PUBLIC_CHECKOUT_DOMAIN` | Recommended | Checkout domain used by analytics and consent |
| `SESSION_SECRET` | Yes | Random string for session encryption |
| `PUBLIC_CUSTOMER_ACCOUNT_API_CLIENT_ID` | If using auth | Customer Account API client ID |
| `PUBLIC_CUSTOMER_ACCOUNT_API_URL` | If using auth/template requires it | Customer Account API URL |
| `SHOP_ID` | If using auth | Shop GID |

## Reference Files

For deeper topics, read the reference files as needed:

- `references/storefront-api-patterns.md`: GraphQL fragments, variants/options, metafields, predictive search, streaming data
- `references/markets-i18n.md`: Markets, locale routing, `@inContext`, and market-aware cart behavior
