import { Component } from '@angular/core';
import { FaIconComponent, IconName, IconPrefix } from '@fortawesome/angular-fontawesome';
import { SectionHead } from '../section-head/section-head';

@Component({
  selector: 'bfs-fw-features',
  imports: [FaIconComponent, SectionHead],
  templateUrl: './features.html',
})
export class Features {
  protected readonly features: { icon: [IconPrefix, IconName]; title: string; text: string }[] = [
    {
      icon: ['far', 'map'],
      title: $localize`:@@features.map.title:Live on the map`,
      text: $localize`:@@features.map.text:Follow several flights at once on OpenStreetMap, from takeoff to landing.`,
    },
    {
      icon: ['far', 'bell'],
      title: $localize`:@@features.notify.title:Get notified`,
      text: $localize`:@@features.notify.text:You get a notification at takeoff, shortly before arrival, and after landing.`,
    },
    {
      icon: ['far', 'shield-check'],
      title: $localize`:@@features.private.title:Private by design`,
      text: $localize`:@@features.private.text:Flugwacht works without an account and doesn't track you. Your flights are only stored on your device.`,
    },
  ];
}
