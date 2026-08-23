import { Component } from '@angular/core';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-screenshots',
  imports: [SectionHead],
  templateUrl: './screenshots.html',
})
export class Screenshots {
  protected readonly captions = [
    $localize`:@@screenshots.map:Map & arrival`,
    $localize`:@@screenshots.today:Today's flights`,
    $localize`:@@screenshots.add:Add a flight`,
  ];
}
