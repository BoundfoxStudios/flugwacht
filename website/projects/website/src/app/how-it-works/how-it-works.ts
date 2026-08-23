import { Component } from '@angular/core';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-how-it-works',
  imports: [SectionHead],
  templateUrl: './how-it-works.html',
})
export class HowItWorks {
  protected readonly steps = [
    {
      number: '01',
      title: $localize`:@@how.broadcast.title:Planes broadcast`,
      text: $localize`:@@how.broadcast.text:Nearly every airliner continuously transmits its position over ADS-B radio.`,
    },
    {
      number: '02',
      title: $localize`:@@how.listen.title:Communities listen`,
      text: $localize`:@@how.listen.text:Thousands of volunteers with small antennas feed open networks like adsb.lol and adsb.fi.`,
    },
    {
      number: '03',
      title: $localize`:@@how.show.title:Flugwacht shows it`,
      text: $localize`:@@how.show.text:Flugwacht reads their open APIs and shows you where your flight is and when it lands.`,
    },
  ];
}
