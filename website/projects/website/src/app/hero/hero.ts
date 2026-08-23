import { Component, LOCALE_ID, inject } from '@angular/core';

@Component({
  selector: 'bfs-fw-hero',
  templateUrl: './hero.html',
})
export class Hero {
  private readonly isGerman = inject(LOCALE_ID).startsWith('de');

  protected readonly appStoreBadge = this.isGerman
    ? '/images/badges/app-store-de.svg'
    : '/images/badges/app-store-en.svg';

  protected readonly playStoreBadge = this.isGerman
    ? '/images/badges/google-play-de.png'
    : '/images/badges/google-play-en.png';
}
