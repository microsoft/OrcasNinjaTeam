package com.yourcompany.conferencedemo.repositories;


import com.yourcompany.conferencedemo.models.Attendee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;

public interface AttendeeRepository extends JpaRepository<Attendee, Long> {
    @Procedure(procedureName = "GET_RANDOM_ATTENDEE")
    Long getRandomAttendee();
}
