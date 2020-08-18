import { Component, OnInit, OnDestroy } from '@angular/core';
import { AttendeeService } from '../services/attendee.service';
import { Attendee } from '../models/attendee';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-registered-attendees-dashboard',
  templateUrl: './registered-attendees-dashboard.component.html'
})
export class RegisteredAttendeesDashboardComponent implements OnInit, OnDestroy {

  attendees: Attendee[] = [];
  private _destroyed$ = new Subject();

  constructor(private attendeeService: AttendeeService) { }

  ngOnInit(): void {
    this.attendeeService.getAttendees().subscribe(data => {
      this.attendees = data;
      takeUntil(this._destroyed$);
    });
  }

  ngOnDestroy(): void {
    this._destroyed$.next(true);
    this._destroyed$.complete();
  }

}
