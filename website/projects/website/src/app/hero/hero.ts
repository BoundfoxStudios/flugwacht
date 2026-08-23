import { Component, LOCALE_ID, inject } from '@angular/core';
import { SITE_TEASER } from '../site-copy';

@Component({
  selector: 'bfs-fw-hero',
  templateUrl: './hero.html',
})
export class Hero {
  protected readonly teaser = SITE_TEASER;

  private readonly locale = inject(LOCALE_ID).startsWith('de') ? 'de' : 'en';

  protected readonly appStoreBadge = `/images/badges/app-store-${this.locale}.svg`;
  protected readonly playStoreBadge = `/images/badges/google-play-${this.locale}.png`;
  protected readonly screenshot = `/images/screens/hero-${this.locale}.webp`;
}
