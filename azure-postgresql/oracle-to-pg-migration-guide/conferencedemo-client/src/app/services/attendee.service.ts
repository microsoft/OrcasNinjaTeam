import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { environment } from 'src/environments/environment';
import { map, catchError } from 'rxjs/operators';
import { Attendee } from '../models/attendee';

@Injectable({
  providedIn: 'root'
})
export class AttendeeService {

  constructor(private http: HttpClient) { }


  getRandomAttendee(): Observable<Attendee> {
    const httpOptions = {
      headers: new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': 'GET'
      })
    };

    return this.http.get<Attendee>(`${environment.webApiUrl}/attendees/randomAttendee`, httpOptions)
      .pipe(
        map(data => {
          return data
        }),
        catchError(data => {
          if (data instanceof HttpErrorResponse && data.status === 404) {
              return [];
            } else {
              this.handleError(data);
            }
        })
      );
  }

  // Get all Attendees
  getAttendees(): Observable<Attendee[]> {
    const httpOptions = {
      headers: new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': 'GET'
      })
    };

    return this.http.get<Attendee[]>(`${environment.webApiUrl}/attendees`, httpOptions)
      .pipe(
        map(data => {
          return data
        }),
        catchError(data => {
          if (data instanceof HttpErrorResponse && data.status === 404) {
              return [];
            } else {
              this.handleError(data);
            }
        })
      );
  }

  private handleError(error: HttpErrorResponse) {
    if (error.error instanceof ErrorEvent) {
      // A client-side or network error occurred. Handle it accordingly.
      console.error('An error occurred:', error.error.message);
    } else {
      // The backend returned an unsuccessful response code.
      // The response body may contain clues as to what went wrong,
      console.error(
        `Backend returned code ${error.status}, ` +
        `body was: ${error.error}`);
    }
    // return an observable with a user-facing error message
    return throwError('Something bad happened; please try again later.');
  }
}
