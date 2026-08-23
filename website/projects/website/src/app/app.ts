import { Component, DOCUMENT, LOCALE_ID, inject } from '@angular/core';
import { DataSources } from './data-sources/data-sources';
import { Features } from './features/features';
import { Footer } from './footer/footer';
import { Hero } from './hero/hero';
import { HowItWorks } from './how-it-works/how-it-works';
import { Navigation } from './navigation/navigation';
import { Screenshots } from './screenshots/screenshots';

@Component({
  imports: [Navigation, Hero, Features, Screenshots, HowItWorks, DataSources, Footer],
  selector: 'bfs-fw-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  constructor() {
    inject(DOCUMENT).documentElement.lang = inject(LOCALE_ID);
  }
}
