import {
  DOCUMENT,
  EnvironmentProviders,
  LOCALE_ID,
  inject,
  provideAppInitializer,
} from '@angular/core';
import { Meta, MetaDefinition, Title } from '@angular/platform-browser';
import { SITE_TEASER } from './site-copy';

const SITE = 'https://flugwacht.app';
const SOCIAL_CARD = `${SITE}/images/social-card.png`;

const ALTERNATES = [
  { hreflang: 'en', href: `${SITE}/` },
  { hreflang: 'de', href: `${SITE}/de/` },
  { hreflang: 'x-default', href: `${SITE}/` },
];

export function provideSeo(): EnvironmentProviders {
  return provideAppInitializer(() => {
    const document = inject(DOCUMENT);
    const isGerman = inject(LOCALE_ID).startsWith('de');

    const title = $localize`:@@seo.title:Flugwacht – Simple flight tracking for friends & family`;
    const canonical = isGerman ? `${SITE}/de/` : `${SITE}/`;

    inject(Title).setTitle(title);

    // The prerendered document already carries these, and hydration runs the initializer a
    // second time in the browser, so every write has to update in place rather than append.
    const meta = inject(Meta);
    const tags: MetaDefinition[] = [
      { name: 'description', content: SITE_TEASER },
      { property: 'og:type', content: 'website' },
      { property: 'og:site_name', content: 'Flugwacht' },
      { property: 'og:locale', content: isGerman ? 'de_DE' : 'en_US' },
      { property: 'og:title', content: title },
      { property: 'og:description', content: SITE_TEASER },
      { property: 'og:url', content: canonical },
      { property: 'og:image', content: SOCIAL_CARD },
      { property: 'og:image:width', content: '1280' },
      { property: 'og:image:height', content: '640' },
      { property: 'og:image:alt', content: 'Flugwacht' },
      { name: 'twitter:card', content: 'summary_large_image' },
      { name: 'twitter:title', content: title },
      { name: 'twitter:description', content: SITE_TEASER },
      { name: 'twitter:image', content: SOCIAL_CARD },
    ];
    for (const tag of tags) {
      meta.updateTag(tag);
    }

    const link = (selector: string, attributes: Record<string, string>) => {
      const element =
        document.head.querySelector(selector) ??
        document.head.appendChild(document.createElement('link'));
      for (const [name, value] of Object.entries(attributes)) {
        element.setAttribute(name, value);
      }
    };

    link('link[rel="canonical"]', { rel: 'canonical', href: canonical });
    for (const alternate of ALTERNATES) {
      link(`link[rel="alternate"][hreflang="${alternate.hreflang}"]`, {
        rel: 'alternate',
        hreflang: alternate.hreflang,
        href: alternate.href,
      });
    }
  });
}
