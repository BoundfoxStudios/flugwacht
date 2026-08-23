import { Component, LOCALE_ID, inject } from '@angular/core';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';
import { Logo } from '../logo/logo';

@Component({
  selector: 'bfs-fw-navigation',
  imports: [FaIconComponent, Logo],
  templateUrl: './navigation.html',
})
export class Navigation {
  protected readonly isGerman = inject(LOCALE_ID).startsWith('de');
}
