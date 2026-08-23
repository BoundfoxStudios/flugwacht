import { Component, LOCALE_ID, inject } from '@angular/core';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-screenshots',
  imports: [SectionHead],
  templateUrl: './screenshots.html',
})
export class Screenshots {
  private readonly locale = inject(LOCALE_ID).startsWith('de') ? 'de' : 'en';

  protected readonly screens = [
    {
      image: `/images/screens/hero-${this.locale}.webp`,
      caption: $localize`:@@screenshots.map:Map & arrival`,
    },
    {
      image: `/images/screens/flights-${this.locale}.webp`,
      caption: $localize`:@@screenshots.today:Today's flights`,
    },
    {
      image: `/images/screens/settings-${this.locale}.webp`,
      caption: $localize`:@@screenshots.settings:Settings`,
    },
  ];
}
