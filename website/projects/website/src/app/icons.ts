import { EnvironmentProviders, inject, provideAppInitializer } from '@angular/core';
import { FaIconLibrary } from '@fortawesome/angular-fontawesome';
import { faDiscord, faGithub } from '@fortawesome/free-brands-svg-icons';
import {
  faArrowUpRight,
  faBell,
  faMap,
  faSatelliteDish,
  faShieldCheck,
} from '@fortawesome/pro-regular-svg-icons';

export function provideIcons(): EnvironmentProviders {
  return provideAppInitializer(() => {
    inject(FaIconLibrary).addIcons(
      faMap,
      faBell,
      faShieldCheck,
      faSatelliteDish,
      faArrowUpRight,
      faGithub,
      faDiscord,
    );
  });
}
