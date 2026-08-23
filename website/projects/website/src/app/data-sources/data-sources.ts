import { Component } from '@angular/core';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-data-sources',
  imports: [FaIconComponent, SectionHead],
  templateUrl: './data-sources.html',
})
export class DataSources {
  protected readonly sources = [
    {
      name: 'ADSB.LOL',
      url: 'https://adsb.lol',
      text: $localize`:@@sources.lol.text:Open, community-run ADS-B network with a free public API.`,
    },
    {
      name: 'ADSB.FI',
      url: 'https://adsb.fi',
      text: $localize`:@@sources.fi.text:Community ADS-B aggregator run by hobbyists, open and non-commercial.`,
    },
  ];
}
