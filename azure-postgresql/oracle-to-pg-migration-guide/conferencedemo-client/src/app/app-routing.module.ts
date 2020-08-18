import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { EventDashboardComponent } from './event-dashboard/event-dashboard.component';
import { SessionSpeakerComponent } from './session-speaker/session-speaker.component';
import { RegisteredAttendeesDashboardComponent } from './registered-attendees-dashboard/registered-attendees-dashboard.component';
import { SpeakerComponent } from './speaker/speaker.component'


const routes: Routes = [
  { path: 'event-dashboard', component: EventDashboardComponent },
  { path: '', redirectTo: 'event-dashboard', pathMatch: 'full' },
  { path: 'sessionspeaker/:eventId', component: SessionSpeakerComponent },
  { path: 'attendees', component: RegisteredAttendeesDashboardComponent },
  { path: 'speaker/:speakerId', component: SpeakerComponent },
  { path: '', component: EventDashboardComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})

export class AppRoutingModule { }
