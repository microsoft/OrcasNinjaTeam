package com.yourcompany.conferencedemo.repositories;

import com.yourcompany.conferencedemo.models.Registration;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;

public interface RegistrationRepository extends JpaRepository<Registration, Long> {

    // This stored procedure should be deprecated and the business logic should be moved to the Java app.
    // This example is contrived, but the principle idea is valid. Unless there is a performance reason to have the business logic in a stored procedure
    // the application should have all of the business logic. You can write unit tests against the business logic.
    @Procedure(procedureName = "REGISTER_ATTENDEE_SESSION")
    void registerAttendee(@Param("P_SESSION_ID")long sessionId, @Param("P_ATTENDEE_ID") long attendeeId);


}
